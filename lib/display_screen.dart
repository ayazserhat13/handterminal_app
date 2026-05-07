import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handterminal_app/core/fb10/fb10_commands.dart';
import 'package:handterminal_app/core/fb10/fb10_display_frame.dart';
import 'package:handterminal_app/core/fb10/fb10_frame_parser.dart';
import 'package:handterminal_app/core/fb10/fb10_write_queue.dart';
import 'package:handterminal_app/l10n/app_localizations.dart';

enum DisplaySessionState { idle, handshaking, terminalReady, error }

class DisplayScreen extends StatefulWidget {
  final BluetoothCharacteristic writeCharacteristic;
  final BluetoothCharacteristic notifyCharacteristic;

  const DisplayScreen({
    super.key,
    required this.writeCharacteristic,
    required this.notifyCharacteristic,
  });

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  static const bool _verboseTrafficLogging = false;
  static const Duration _statsLogInterval = Duration(seconds: 1);

  int? _heldKeyValue;
  bool _heldKeyActive = false;

  Timer? _idlePollTimer;
  Timer? _statsTimer;
  DateTime _lastKeySentAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastFrameAt;
  DateTime? _lastPollAt;
  DateTime? _lastRxAt;
  DateTime? _lastStatsAt;

  bool _keySequenceInProgress = false;

  void _startLongPress(int key) async {
    if (_heldKeyActive) return;

    _heldKeyActive = true;
    _heldKeyValue = key;

    _suppressSingleByteEcho = true;

    await _writeBytes([key]);
  }

  void _stopLongPress() async {
    if (!_heldKeyActive) return;

    _heldKeyActive = false;
    _heldKeyValue = null;

    await _writeBytes(const [Fb10Commands.idle]);

    _lastKeySentAt = DateTime.now();
  }

  List<String> lines = const [
    '                ',
    '                ',
    '                ',
    '                ',
  ];

  bool ledLeft = false;
  bool ledRight = false;

  DisplaySessionState sessionState = DisplaySessionState.idle;
  String statusText = '';

  StreamSubscription<List<int>>? _notifyStreamSub;
  final Fb10FrameParser _frameParser = Fb10FrameParser(
    debugLogging: _verboseTrafficLogging,
  );
  late final Fb10WriteQueue _writeQueue;

  Timer? _handshakeTimer;

  int _handshakeTryCount = 0;

  bool _waitingForFirstBb = false;
  bool _waitingForSecondBb = false;
  bool _terminalStarted = false;
  bool _busySending = false;

  bool _suppressSingleByteEcho = false;

  int _rxChunks = 0;
  int _rxBytes = 0;
  int _framesEmitted = 0;
  int _txPolls = 0;
  int _pollIntervalCount = 0;
  int _pollIntervalTotalMs = 0;
  int? _pollIntervalMinMs;
  int? _pollIntervalMaxMs;
  int _writeDurationCount = 0;
  int _writeDurationTotalMs = 0;
  int? _writeDurationMinMs;
  int? _writeDurationMaxMs;

  @override
  void initState() {
    super.initState();
    _writeQueue = Fb10WriteQueue(writer: _writeBytesDirect);
    _startStatsLogging();
    _listenNotify();
    Future.microtask(() async {
      await _startTerminalHandshake();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (statusText.isEmpty) {
      statusText = AppLocalizations.of(context).statusPreparingConnection;
    }
  }

  @override
  void dispose() {
    _idlePollTimer?.cancel();
    _statsTimer?.cancel();
    _notifyStreamSub?.cancel();
    _handshakeTimer?.cancel();
    _writeQueue.close();
    super.dispose();
  }

  void _log(String text) {
    debugPrint('DISPLAY: $text');
  }

  void _logTrafficBytes(String direction, List<int> bytes) {
    if (!_verboseTrafficLogging) return;

    _log(
      '$direction LEN: ${bytes.length} | HEX: ${bytes.map(_formatByte).join(' ')}',
    );
  }

  String _formatByte(int byte) {
    return byte.toRadixString(16).padLeft(2, '0');
  }

  void _startStatsLogging() {
    _statsTimer?.cancel();
    _lastStatsAt = DateTime.now();
    _statsTimer = Timer.periodic(_statsLogInterval, (_) {
      _logTrafficStats();
    });
  }

  void _logTrafficStats() {
    final now = DateTime.now();
    final rxChunks = _rxChunks;
    final rxBytes = _rxBytes;
    final framesEmitted = _framesEmitted;
    final txPolls = _txPolls;
    final pollIntervalCount = _pollIntervalCount;
    final pollIntervalMinMs = _pollIntervalMinMs;
    final pollIntervalAvgMs = pollIntervalCount == 0
        ? null
        : _pollIntervalTotalMs / pollIntervalCount;
    final pollIntervalMaxMs = _pollIntervalMaxMs;
    final writeDurationCount = _writeDurationCount;
    final writeDurationMinMs = _writeDurationMinMs;
    final writeDurationAvgMs = writeDurationCount == 0
        ? null
        : _writeDurationTotalMs / writeDurationCount;
    final writeDurationMaxMs = _writeDurationMaxMs;
    final statsElapsedMs = _lastStatsAt == null
        ? _statsLogInterval.inMilliseconds
        : now.difference(_lastStatsAt!).inMilliseconds;
    final framesPerSecond = statsElapsedMs <= 0
        ? 0.0
        : framesEmitted * 1000 / statsElapsedMs;
    final lastFrameAgeMs = _lastFrameAt == null
        ? null
        : now.difference(_lastFrameAt!).inMilliseconds;
    final lastPollAgeMs = _lastPollAt == null
        ? null
        : now.difference(_lastPollAt!).inMilliseconds;
    final lastRxAgeMs = _lastRxAt == null
        ? null
        : now.difference(_lastRxAt!).inMilliseconds;

    _lastStatsAt = now;
    _rxChunks = 0;
    _rxBytes = 0;
    _framesEmitted = 0;
    _txPolls = 0;
    _pollIntervalCount = 0;
    _pollIntervalTotalMs = 0;
    _pollIntervalMinMs = null;
    _pollIntervalMaxMs = null;
    _writeDurationCount = 0;
    _writeDurationTotalMs = 0;
    _writeDurationMinMs = null;
    _writeDurationMaxMs = null;

    if (rxChunks == 0 &&
        rxBytes == 0 &&
        framesEmitted == 0 &&
        txPolls == 0 &&
        pollIntervalCount == 0 &&
        writeDurationCount == 0) {
      return;
    }

    _log(
      'STATS rxChunks=$rxChunks rxBytes=$rxBytes '
      'framesEmitted=$framesEmitted txPolls=$txPolls '
      'framesPerSecond=${framesPerSecond.toStringAsFixed(1)} '
      'pollIntervalMs=${_formatTimingStats(pollIntervalMinMs, pollIntervalAvgMs, pollIntervalMaxMs)} '
      'writeDurationMs=${_formatTimingStats(writeDurationMinMs, writeDurationAvgMs, writeDurationMaxMs)} '
      'parserBufferLength=${_frameParser.bufferedByteCount} '
      'lastRxAgeMs=${lastRxAgeMs ?? -1} '
      'lastFrameAgeMs=${lastFrameAgeMs ?? -1} '
      'pollTimerActive=${_idlePollTimer?.isActive == true} '
      'lastPollAgeMs=${lastPollAgeMs ?? -1}',
    );
  }

  String _formatTimingStats(int? minMs, double? avgMs, int? maxMs) {
    if (minMs == null || avgMs == null || maxMs == null) {
      return 'min=-1 avg=-1 max=-1';
    }

    return 'min=$minMs avg=${avgMs.toStringAsFixed(1)} max=$maxMs';
  }

  void _recordPollSent(DateTime sentAt) {
    final previousPollAt = _lastPollAt;

    if (previousPollAt != null) {
      _recordPollInterval(sentAt.difference(previousPollAt).inMilliseconds);
    }

    _lastPollAt = sentAt;
  }

  void _recordPollInterval(int intervalMs) {
    _pollIntervalCount++;
    _pollIntervalTotalMs += intervalMs;
    _pollIntervalMinMs = _pollIntervalMinMs == null
        ? intervalMs
        : _min(_pollIntervalMinMs!, intervalMs);
    _pollIntervalMaxMs = _pollIntervalMaxMs == null
        ? intervalMs
        : _max(_pollIntervalMaxMs!, intervalMs);
  }

  void _recordWriteDuration(int durationMs) {
    _writeDurationCount++;
    _writeDurationTotalMs += durationMs;
    _writeDurationMinMs = _writeDurationMinMs == null
        ? durationMs
        : _min(_writeDurationMinMs!, durationMs);
    _writeDurationMaxMs = _writeDurationMaxMs == null
        ? durationMs
        : _max(_writeDurationMaxMs!, durationMs);
  }

  int _min(int a, int b) {
    return a < b ? a : b;
  }

  int _max(int a, int b) {
    return a > b ? a : b;
  }

  Future<void> _writeBytes(List<int> bytes) async {
    await _writeQueue.enqueue(bytes);
  }

  Future<void> _writeBytesDirect(List<int> bytes) async {
    final stopwatch = Stopwatch()..start();

    try {
      await widget.writeCharacteristic.write(
        bytes,
        withoutResponse:
            widget.writeCharacteristic.properties.writeWithoutResponse,
      );
    } finally {
      stopwatch.stop();
      _recordWriteDuration(stopwatch.elapsedMilliseconds);
    }

    _logTrafficBytes('TX', bytes);
  }

  Future<void> _sendIdlePoll() async {
    if (_heldKeyActive) return;

    if (sessionState != DisplaySessionState.terminalReady) return;
    if (_keySequenceInProgress) return;
    if (_writeQueue.isBusy) return;

    //final now = DateTime.now();

    // Tuştan hemen sonra idle poll gönderme
    //if (now.difference(_lastKeySentAt) < Fb10Timings.idleAfterKeyGuard) {
    //  return;
    //}

    try {
      _suppressSingleByteEcho = true;
      await _writeBytes(const [Fb10Commands.idle]);
      _recordPollSent(DateTime.now());
      _txPolls++;
    } catch (e) {
      _log('IDLE POLL ERROR: $e');
    }
  }

  void _listenNotify() {
    _notifyStreamSub = widget.notifyCharacteristic.lastValueStream.listen((
      value,
    ) {
      if (value.isEmpty) return;

      _lastRxAt = DateTime.now();
      _rxChunks++;
      _rxBytes += value.length;
      _logTrafficBytes('RX', value);

      if (_waitingForFirstBb || _waitingForSecondBb) {
        _handleHandshakeBytes(value);
        return;
      }

      if (!_terminalStarted) return;

      // Tek byte echo'ları yok say
      if (value.length == 1 && _suppressSingleByteEcho) {
        final b = value.first;
        if ((b & 0xF0) == 0xA0 || Fb10Commands.singleByteEchoes.contains(b)) {
          _log('Single-byte echo ignored: ${b.toRadixString(16)}');
          _suppressSingleByteEcho = false;
          return;
        }
      }

      final frames = _frameParser.addBytes(value);
      _framesEmitted += frames.length;
      for (final frame in frames) {
        _applyDisplayFrame(frame);
      }
    });
  }

  Future<void> _startTerminalHandshake() async {
    if (_busySending) return;
    _busySending = true;

    try {
      setState(() {
        sessionState = DisplaySessionState.handshaking;
        statusText = AppLocalizations.of(context).statusHandshakeStarting;
      });

      _frameParser.clear();
      _waitingForFirstBb = true;
      _waitingForSecondBb = false;
      _terminalStarted = false;
      _handshakeTryCount = 0;

      _handshakeTimer?.cancel();

      _handshakeTimer = Timer.periodic(Fb10Timings.handshakeRetryInterval, (
        timer,
      ) async {
        if (!_waitingForFirstBb) {
          timer.cancel();
          return;
        }

        _handshakeTryCount++;
        _log('Handshake deneme: $_handshakeTryCount');

        if (_handshakeTryCount > 100) {
          timer.cancel();
          if (mounted) {
            setState(() {
              sessionState = DisplaySessionState.error;
              statusText = AppLocalizations.of(context).statusBbTimeout;
            });
          }
          return;
        }

        try {
          if (_writeQueue.isBusy) return;
          await _writeBytes(const [Fb10Commands.handshakeWake]);
          await Future.delayed(Fb10Timings.handshakeCommandGap);
          if (!_waitingForFirstBb) return;
          await _writeBytes(const [Fb10Commands.handshakeRequest]);
        } catch (e) {
          _log('Handshake send error: $e');
        }
      });

      setState(() {
        statusText = AppLocalizations.of(context).statusWaitingForBb;
      });
    } catch (e) {
      setState(() {
        sessionState = DisplaySessionState.error;
        statusText = AppLocalizations.of(
          context,
        ).statusHandshakeError(e.toString());
      });
    } finally {
      _busySending = false;
    }
  }

  void _handleHandshakeBytes(List<int> value) async {
    final hasBb = value.contains(Fb10Commands.handshakeResponse);

    if (_waitingForFirstBb) {
      if (!hasBb) {
        _log('Handshake stage 1: BB yok, veri yok sayıldı');
        return;
      }

      _handshakeTimer?.cancel();
      _waitingForFirstBb = false;
      _waitingForSecondBb = true;
      _writeQueue.clearPending();

      setState(() {
        statusText = AppLocalizations.of(context).statusFirstBbReceived;
      });

      await _writeBytes(const [Fb10Commands.handshakeAck]);
      return;
    }

    if (_waitingForSecondBb) {
      if (!hasBb) {
        _log('Handshake stage 2: BB yok, veri yok sayıldı');
        return;
      }

      _waitingForSecondBb = false;
      _writeQueue.clearPending();

      setState(() {
        statusText = AppLocalizations.of(context).statusSecondBbReceived;
      });

      await _startTerminalMode();
    }
  }

  Future<void> _startTerminalMode() async {
    try {
      _frameParser.clear();
      await _writeBytes(const [Fb10Commands.startTerminal]);
      _terminalStarted = true;

      setState(() {
        sessionState = DisplaySessionState.terminalReady;
        statusText = AppLocalizations.of(context).statusTerminalReady;
      });

      _startIdlePolling();

      // İlk ekran için ilk idle poll
      await Future.delayed(Fb10Timings.firstIdlePollDelay);
      await _sendIdlePoll();
    } catch (e) {
      setState(() {
        sessionState = DisplaySessionState.error;
        statusText = AppLocalizations.of(
          context,
        ).statusTerminalStartError(e.toString());
      });
    }
  }

  void _startIdlePolling() {
    _idlePollTimer?.cancel();

    _idlePollTimer = Timer.periodic(Fb10Timings.idlePollInterval, (_) {
      _sendIdlePoll();
    });
  }

  void _applyDisplayFrame(Fb10DisplayFrame frame) {
    _lastFrameAt = DateTime.now();

    setState(() {
      lines = frame.lines;
      ledLeft = frame.errorLed;
      ledRight = frame.operateLed;
      statusText = AppLocalizations.of(context).statusTerminalReady;
    });

    // Frame geldi, artık yeni poll gönderebiliriz
    _suppressSingleByteEcho = false;

    if (_heldKeyActive && _heldKeyValue != null) {
      Future.delayed(Fb10Timings.repeatKeyDelay, () async {
        if (!mounted) return;
        if (!_heldKeyActive) return;
        if (_heldKeyValue == null) return;
        if (_writeQueue.isBusy) return;

        _suppressSingleByteEcho = true;
        await _writeBytes([_heldKeyValue!]);
      });
    }
  }

  Future<void> _sendKeyByte(int value) async {
      if (sessionState != DisplaySessionState.terminalReady) return;
      if (_keySequenceInProgress) return;

      _keySequenceInProgress = true;

      try {
        _suppressSingleByteEcho = true;

        await _writeBytes([value]);
        await Future.delayed(Fb10Timings.keyPressDuration);
        await _writeBytes(const [Fb10Commands.idle]);

        _lastKeySentAt = DateTime.now();

        // Kritik fark:
        // keyReleaseGuard polling'i bloke etmesin
      } catch (e) {
        _log('KEY SEND ERROR: $e');
        setState(() {
          statusText = AppLocalizations.of(context).statusKeySendError;
        });
      } finally {
        _suppressSingleByteEcho = false;
        _keySequenceInProgress = false;
      }
  }

  Future<void> _sendQuit() => _sendKeyByte(Fb10Commands.quit);
  Future<void> _sendAb() => _sendKeyByte(Fb10Commands.down);
  Future<void> _sendAuf() => _sendKeyByte(Fb10Commands.up);
  Future<void> _sendEnter() => _sendKeyByte(Fb10Commands.enter);

  Future<void> _sendMenu() => _sendKeyByte(Fb10Commands.menu);
  Future<void> _sendMonitor() => _sendKeyByte(Fb10Commands.monitor);
  Future<void> _sendErrors() => _sendKeyByte(Fb10Commands.errors);

  Widget _led(bool state, Color onColor) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state ? onColor : const Color(0xFFE8E8E8),
        border: Border.all(color: Colors.black87, width: 1.4),
        boxShadow: [
          if (state)
            BoxShadow(
              color: onColor.withValues(alpha: 0.65),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(1, 2),
          ),
        ],
      ),
    );
  }

  Widget _display() {
    return Container(
      width: 260,
      height: 162,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B4FA3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(2, 4)),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 250,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines.map((line) {
              return Text(
                line.padRight(16).substring(0, 16),
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 22,
                  height: 1.0,
                  color: Colors.white,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _button(String text, VoidCallback onPressed) {
    return SizedBox(
      width: 76,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE9ECEF),
          foregroundColor: Colors.black,
          elevation: 3,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black54, width: 1),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, maxLines: 1, softWrap: false),
        ),
      ),
    );
  }

  Widget _roundPrimaryButton(String text, VoidCallback onPressed) {
    const blue = Color(0xFF0A4C93);

    return SizedBox(
      width: 68,
      height: 68,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 5,
          shadowColor: blue.withValues(alpha: 0.35),
          padding: const EdgeInsets.all(8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buttonRow(List<Widget> children) {
    return SizedBox(
      width: 342,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      ),
    );
  }

  Color _statusColor() {
    switch (sessionState) {
      case DisplaySessionState.terminalReady:
        return Colors.green;
      case DisplaySessionState.error:
        return Colors.red;
      case DisplaySessionState.handshaking:
        return Colors.orange;
      case DisplaySessionState.idle:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 382,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8E8E8),
                    Color(0xFFC9CDD1),
                    Color(0xFFF4F4F4),
                    Color(0xFFB8BEC4),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Color(0xFF8A9299), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.black87,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  SizedBox(
                    width: 180,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              l10n.errorLed,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _led(ledLeft, Colors.red),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              l10n.operateLed,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _led(ledRight, Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _display(),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 342,
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 11, color: _statusColor()),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buttonRow([
                    _button(l10n.menu, _sendMenu),
                    _button(l10n.monitor, _sendMonitor),
                    _button(l10n.errors, _sendErrors),
                  ]),
                  const SizedBox(height: 10),
                  _buttonRow([
                    _roundPrimaryButton(l10n.quit, _sendQuit),

                    GestureDetector(
                      onLongPressStart: (_) =>
                          _startLongPress(Fb10Commands.down),
                      onLongPressEnd: (_) => _stopLongPress(),
                      onTap: _sendAb,
                      child: _roundPrimaryButton(l10n.ab, _sendAb),
                    ),

                    GestureDetector(
                      onLongPressStart: (_) => _startLongPress(Fb10Commands.up),
                      onLongPressEnd: (_) => _stopLongPress(),
                      onTap: _sendAuf,
                      child: _roundPrimaryButton(l10n.auf, _sendAuf),
                    ),

                    _roundPrimaryButton(l10n.enter, _sendEnter),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
