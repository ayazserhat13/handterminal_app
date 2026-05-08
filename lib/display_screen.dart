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
  static const Duration _displayStartPollInterval = Duration(milliseconds: 250);

  final Set<int> _pressedKeys = <int>{};
  final Set<int> _latchedKeys = <int>{};

  Timer? _displayStartTimer;
  Timer? _statsTimer;
  DateTime? _lastFrameAt;
  DateTime? _lastPollAt;
  DateTime? _lastRxAt;
  DateTime? _lastStatsAt;

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
  bool _terminalStarted = false;
  bool _firstFrameReceived = false;
  bool _busySending = false;

  //bool _suppressSingleByteEcho = false;

  int _rxChunks = 0;
  int _rxBytes = 0;
  int _framesEmitted = 0;
  int _singleByteEchoIgnored = 0;
  int _singleByteFedToParserWhilePartial = 0;
  int _displayStartPolls = 0;
  int _txPolls = 0;
  int _keyTxCount = 0;
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
    _displayStartTimer?.cancel();
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
    final singleByteEchoIgnored = _singleByteEchoIgnored;
    final singleByteFedToParserWhilePartial =
        _singleByteFedToParserWhilePartial;
    final displayStartPolls = _displayStartPolls;
    final txPolls = _txPolls;
    final keyTxCount = _keyTxCount;
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
    _singleByteEchoIgnored = 0;
    _singleByteFedToParserWhilePartial = 0;
    _displayStartPolls = 0;
    _txPolls = 0;
    _keyTxCount = 0;
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
        singleByteEchoIgnored == 0 &&
        singleByteFedToParserWhilePartial == 0 &&
        displayStartPolls == 0 &&
        txPolls == 0 &&
        keyTxCount == 0 &&
        pollIntervalCount == 0 &&
        writeDurationCount == 0) {
      return;
    }

    _log(
      'STATS rxChunks=$rxChunks rxBytes=$rxBytes '
      'framesEmitted=$framesEmitted txPolls=$txPolls keyTxCount=$keyTxCount '
      'displayStartPolls=$displayStartPolls '
      'singleByteEchoIgnored=$singleByteEchoIgnored '
      'singleByteFedToParserWhilePartial=$singleByteFedToParserWhilePartial '
      'framesPerSecond=${framesPerSecond.toStringAsFixed(1)} '
      'pollIntervalMs=${_formatTimingStats(pollIntervalMinMs, pollIntervalAvgMs, pollIntervalMaxMs)} '
      'writeDurationMs=${_formatTimingStats(writeDurationMinMs, writeDurationAvgMs, writeDurationMaxMs)} '
      'parserBufferLength=${_frameParser.bufferedByteCount} '
      'lastRxAgeMs=${lastRxAgeMs ?? -1} '
      'lastFrameAgeMs=${lastFrameAgeMs ?? -1} '
      'displayStartTimerActive=${_displayStartTimer?.isActive == true} '
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

  int _combinedKeyByte() {
    var value = 0;
    for (final key in _pressedKeys) {
      value |= key;
    }
    for (final key in _latchedKeys) {
      value |= key;
    }
    return value;
  }

  void _pressKey(int keyByte) {
    _pressedKeys.add(keyByte);
    _latchedKeys.add(keyByte);
  }

  void _releaseKey(int keyByte) {
    _pressedKeys.remove(keyByte);
  }

  Future<void> _sendScheduledTx() async {
    if (sessionState != DisplaySessionState.terminalReady) return;

    final hasKeysToSend = _pressedKeys.isNotEmpty || _latchedKeys.isNotEmpty;
    final byteToSend = hasKeysToSend ? _combinedKeyByte() : Fb10Commands.idle;

    try {
     // _suppressSingleByteEcho = true;
      await _writeQueue.enqueue([byteToSend]);

      if (byteToSend == Fb10Commands.idle) {
        _recordPollSent(DateTime.now());
        _txPolls++;
      } else {
        _keyTxCount++;
        _latchedKeys.removeWhere((key) => !_pressedKeys.contains(key));
      }
    } catch (e) {
      _log('SCHEDULED TX ERROR: $e');
    }
  }

  Future<void> _sendDisplayStartPoll() async {
    if (sessionState != DisplaySessionState.terminalReady) return;
    if (!_terminalStarted) return;
    if (_firstFrameReceived) return;
    if (_writeQueue.isBusy) return;

    try {
      //_suppressSingleByteEcho = true;
      await _writeBytes(const [Fb10Commands.startTerminal]);
      _displayStartPolls++;
    } catch (e) {
      _log('DISPLAY START POLL ERROR: $e');
    }
  }

  void _startDisplayStartPolling() {
    _displayStartTimer?.cancel();
    _displayStartTimer = Timer.periodic(_displayStartPollInterval, (_) {
      _sendDisplayStartPoll();
    });
    _sendDisplayStartPoll();
  }

  void _stopDisplayStartPolling() {
    _displayStartTimer?.cancel();
    _displayStartTimer = null;
  }

  void _listenNotify() {
    _notifyStreamSub = widget.notifyCharacteristic.onValueReceived.listen((
      value,
    ) {
      if (value.isEmpty) return;

      _lastRxAt = DateTime.now();
      _rxChunks++;
      _rxBytes += value.length;
      _logTrafficBytes('RX', value);

      if (_waitingForFirstBb) {
        _handleHandshakeBytes(value);
        return;
      }

      if (!_terminalStarted) return;

      // Tek byte echo'ları yok say
      //if (value.length == 1 && _suppressSingleByteEcho) {
      //    final b = value.first;
      //    if ((b & 0xF0) == 0xA0 || //Fb10Commands.singleByteEchoes.contains(b)) {
        //    if (_frameParser.bufferedByteCount > 0) {
        //      _singleByteFedToParserWhilePartial++;
        //      _suppressSingleByteEcho = false;
        //    } else {
         //     _singleByteEchoIgnored++;
         //     _suppressSingleByteEcho = false;
        //      return;
       //     }
      //    }
     // }

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
        _terminalStarted = false;
        _firstFrameReceived = false;
        _handshakeTryCount = 0;

        _stopDisplayStartPolling();
        _handshakeTimer?.cancel();

        var sendWakeNext = true;

        setState(() {
          statusText = AppLocalizations.of(context).statusWaitingForBb;
        });

        _handshakeTimer = Timer.periodic(
          Fb10Timings.handshakeRetryInterval,
          (timer) async {
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

              final byteToSend = sendWakeNext
                  ? Fb10Commands.handshakeWake
                  : Fb10Commands.handshakeRequest;

              sendWakeNext = !sendWakeNext;

              await _writeBytes([byteToSend]);
            } catch (e) {
              _log('Handshake send error: $e');
            }
          },
        );

        await _writeBytes(const [Fb10Commands.handshakeWake]);
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
      _log(
        'Handshake RX raw: ${value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );

      final hasBb = value.contains(Fb10Commands.handshakeResponse);

      if (!_waitingForFirstBb) return;

      if (!hasBb) {
          _log('Handshake stage 1: BB yok, veri bekleniyor');
          return;
      }

      _log('Handshake stage 1: BB geldi, 0xAA gönderiliyor');

      _handshakeTimer?.cancel();
      _waitingForFirstBb = false;
      _writeQueue.clearPending();

      setState(() {
        statusText = AppLocalizations.of(context).statusFirstBbReceived;
      });

      await _writeBytes(const [Fb10Commands.handshakeAck]);
      await _startTerminalMode();
  }

  Future<void> _startTerminalMode() async {
      try {
        _frameParser.clear();
        _terminalStarted = true;
        _firstFrameReceived = false;
        //_suppressSingleByteEcho = true;

        setState(() {
          sessionState = DisplaySessionState.terminalReady;
          statusText = AppLocalizations.of(context).statusTerminalReady;
        });

        _startDisplayStartPolling();
      } catch (e) {
        setState(() {
          sessionState = DisplaySessionState.error;
          statusText = AppLocalizations.of(
            context,
          ).statusTerminalStartError(e.toString());
        });
      }
  }

  void _applyDisplayFrame(Fb10DisplayFrame frame) {
    _lastFrameAt = DateTime.now();
    if (!_firstFrameReceived) {
      _firstFrameReceived = true;
      _stopDisplayStartPolling();
    }

    setState(() {
      lines = frame.lines;
      ledLeft = frame.errorLed;
      ledRight = frame.operateLed;
      statusText = AppLocalizations.of(context).statusTerminalReady;
    });

    // Frame geldi, artık yeni poll gönderebiliriz
    //_suppressSingleByteEcho = false;
    _sendScheduledTx();
  }

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

  Widget _keyPressListener({required int keyByte, required Widget child}) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _pressKey(keyByte),
      onPointerUp: (_) => _releaseKey(keyByte),
      onPointerCancel: (_) => _releaseKey(keyByte),
      child: child,
    );
  }

  Widget _button(String text, int keyByte) {
    return _keyPressListener(
      keyByte: keyByte,
      child: SizedBox(
        width: 76,
        height: 44,
        child: ElevatedButton(
          onPressed: () {},
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
      ),
    );
  }

  Widget _roundPrimaryButton(String text, int keyByte) {
    const blue = Color(0xFF0A4C93);

    return _keyPressListener(
      keyByte: keyByte,
      child: SizedBox(
        width: 68,
        height: 68,
        child: ElevatedButton(
          onPressed: () {},
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
                    _button(l10n.menu, Fb10Commands.menu),
                    _button(l10n.monitor, Fb10Commands.monitor),
                    _button(l10n.errors, Fb10Commands.errors),
                  ]),
                  const SizedBox(height: 10),
                  _buttonRow([
                    _roundPrimaryButton(l10n.quit, Fb10Commands.quit),
                    _roundPrimaryButton(l10n.ab, Fb10Commands.down),
                    _roundPrimaryButton(l10n.auf, Fb10Commands.up),
                    _roundPrimaryButton(l10n.enter, Fb10Commands.enter),
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
