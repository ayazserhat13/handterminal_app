import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DisplaySessionState {
  idle,
  handshaking,
  terminalReady,
  error,
}

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
  static const int _idleKey = 0xAF;
  int? _lockedOffset;
  List<String> lines = const [
    '                ',
    '                ',
    '                ',
    '                ',
  ];

  bool ledLeft = false;
  bool ledRight = false;

  DisplaySessionState sessionState = DisplaySessionState.idle;
  String statusText = 'Bağlantı hazırlanıyor...';

  StreamSubscription<List<int>>? _notifyStreamSub;
  final List<int> _frameBuffer = <int>[];

  Timer? _handshakeTimer;

  int _handshakeTryCount = 0;

  bool _waitingForFirstBb = false;
  bool _waitingForSecondBb = false;
  bool _terminalStarted = false;
  bool _busySending = false;

  bool _waitingForFrameAfterKey = false;
  bool _pollInFlight = false;
  bool _suppressSingleByteEcho = false;

  @override
  void initState() {
    super.initState();
    _listenNotify();
    Future.microtask(() async {
      await _startTerminalHandshake();
    });
  }

  @override
  void dispose() {
    _notifyStreamSub?.cancel();
    _handshakeTimer?.cancel();
    super.dispose();
  }

  void _log(String text) {
    //debugPrint('DISPLAY: $text');
  }

  Future<void> _writeBytes(List<int> bytes) async {
    await widget.writeCharacteristic.write(
      bytes,
      withoutResponse: widget.writeCharacteristic.properties.writeWithoutResponse,
    );

    _log(
      'TX LEN: ${bytes.length} | HEX: ${bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}',
    );
  }

  Future<void> _sendIdlePoll() async {
    if (sessionState != DisplaySessionState.terminalReady) return;
    if (_pollInFlight) return;

    _pollInFlight = true;
    _suppressSingleByteEcho = true;

    try {
      await _writeBytes(const [_idleKey]);
    } catch (e) {
      _log('IDLE POLL ERROR: $e');
      _pollInFlight = false;
    }
  }

  void _listenNotify() {
    _notifyStreamSub = widget.notifyCharacteristic.lastValueStream.listen((value) {
      if (value.isEmpty) return;

      _log(
        'RX LEN: ${value.length} | HEX: ${value.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}',
      );

      if (_waitingForFirstBb || _waitingForSecondBb) {
        _handleHandshakeBytes(value);
        return;
      }

      if (!_terminalStarted) return;

      // Tek byte echo'ları yok say
      if (value.length == 1 && _suppressSingleByteEcho) {
        final b = value.first;
        if ((b & 0xF0) == 0xA0 || b == 0x00 || b == 0x03 || b == 0x50 || b == 0xAA) {
          _log('Single-byte echo ignored: ${b.toRadixString(16)}');
          _suppressSingleByteEcho = false;
          return;
        }
      }

      _frameBuffer.addAll(value);
      if (_frameBuffer.length > 512) {
          _log('Buffer trimmed from ${_frameBuffer.length}');
          _frameBuffer.removeRange(0, _frameBuffer.length - 130);
        }
      _consumeFrames();
    });
  }

  Future<void> _startTerminalHandshake() async {
    if (_busySending) return;
    _busySending = true;

    try {
      setState(() {
        sessionState = DisplaySessionState.handshaking;
        statusText = 'Handshake başlatılıyor...';
      });

      _frameBuffer.clear();
      _waitingForFirstBb = true;
      _waitingForSecondBb = false;
      _terminalStarted = false;
      _handshakeTryCount = 0;

      _handshakeTimer?.cancel();

      _handshakeTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
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
              statusText = 'Timeout: 0xBB alınamadı';
            });
          }
          return;
        }

        try {
          await _writeBytes(const [0x00]);
          await Future.delayed(const Duration(milliseconds: 40));
          await _writeBytes(const [0x03]);
        } catch (e) {
          _log('Handshake send error: $e');
        }
      });

      setState(() {
        statusText = '0xBB bekleniyor...';
      });
    } catch (e) {
      setState(() {
        sessionState = DisplaySessionState.error;
        statusText = 'Handshake hatası: $e';
      });
    } finally {
      _busySending = false;
    }
  }

  void _handleHandshakeBytes(List<int> value) async {
    final hasBb = value.contains(0xBB);

    if (_waitingForFirstBb) {
      if (!hasBb) {
        _log('Handshake stage 1: BB yok, veri yok sayıldı');
        return;
      }

      _handshakeTimer?.cancel();
      _waitingForFirstBb = false;
      _waitingForSecondBb = true;

      setState(() {
        statusText = 'İlk 0xBB alındı, 0xAA gönderiliyor...';
      });

      await _writeBytes(const [0xAA]);
      return;
    }

    if (_waitingForSecondBb) {
      if (!hasBb) {
        _log('Handshake stage 2: BB yok, veri yok sayıldı');
        return;
      }

      _waitingForSecondBb = false;

      setState(() {
        statusText = 'İkinci 0xBB alındı, terminal başlatılıyor...';
      });

      await _startTerminalMode();
    }
  }

  Future<void> _startTerminalMode() async {
    try {
      _frameBuffer.clear();
      _pollInFlight = false;
      _waitingForFrameAfterKey = false;

      await _writeBytes(const [0x50]);
      _terminalStarted = true;

      setState(() {
        sessionState = DisplaySessionState.terminalReady;
        statusText = 'Terminal hazır';
      });

      // İlk ekran için ilk idle poll
      await Future.delayed(const Duration(milliseconds: 60));
      await _sendIdlePoll();
    } catch (e) {
      setState(() {
        sessionState = DisplaySessionState.error;
        statusText = 'Terminal başlatma hatası: $e';
      });
    }
  }

  bool _isDisplayChar(int b) {
    return (b >= 32 && b <= 126) || b == 0 || b == 1 || b == 2 || b >= 128;
  }

  bool _looksLikeValidFrame(List<int> frame) {
  if (frame.length != 65) return false;

  final status = frame[64];

  // Status mutlaka 0x5? olmalı
  if ((status & 0xF0) != 0x50) return false;

  // Ekran karakter kalitesi
  final printableCount = frame.sublist(0, 64).where((b) {
    return (b >= 32 && b <= 126) || b >= 128;
  }).length;

  // Daha sıkı threshold (önceden 40 idi)
  if (printableCount < 52) return false;

  // Çok fazla kontrol karakteri varsa reddet
  final controlCount = frame.sublist(0, 64).where((b) {
    return b < 32 && b != 0 && b != 1 && b != 2;
  }).length;

  if (controlCount > 4) return false;

  return true;
}

void _consumeFrames() {
  while (_frameBuffer.length >= 65) {
    // Eğer buffer başında önceki frame'den kalmış status byte varsa temizle.
    // 0x50=P, 0x51=Q, 0x52=R, 0x53=S
    if (_frameBuffer.length >= 66 &&
        (_frameBuffer[0] & 0xF0) == 0x50) {
      final shiftedCandidate = _frameBuffer.sublist(1, 66);
      if (_looksLikeValidFrame(shiftedCandidate)) {
        _frameBuffer.removeAt(0);
        continue;
      }
    }

    int? startIndex;

    for (int i = 0; i <= _frameBuffer.length - 65; i++) {
      final candidate = _frameBuffer.sublist(i, i + 65);

      // Eğer aday Q/P/R/S ile başlıyor ve bir sonraki byte'tan başlayan aday geçerliyse,
      // bu aday muhtemelen status byte ile kaymıştır; bunu seçme.
      if ((candidate[0] & 0xF0) == 0x50 &&
          i + 66 <= _frameBuffer.length) {
        final shiftedCandidate = _frameBuffer.sublist(i + 1, i + 66);
        if (_looksLikeValidFrame(shiftedCandidate)) {
          startIndex = i + 1;
          break;
        }
      }

      if (_looksLikeValidFrame(candidate)) {
        startIndex = i;
        break;
      }
    }

    if (startIndex == null) {
      if (_frameBuffer.length > 130) {
        _frameBuffer.removeAt(0);
      }
      return;
    }

    if (startIndex > 0) {
      _frameBuffer.removeRange(0, startIndex);
    }

    if (_frameBuffer.length < 65) return;

    final frame = _frameBuffer.sublist(0, 65);
    _frameBuffer.removeRange(0, 65);

    // Status byte kayması: P/Q/R/S ekranın ilk karakteri olduysa bu frame'i gösterme.
    // Bir sonraki frame zaten kendiliğinden doğru hizaya geliyor.
    if ((frame[0] & 0xF0) == 0x50) {
      return;
    }

    _parseFrame(frame);

    while (_frameBuffer.isNotEmpty && (_frameBuffer.first & 0xF0) == 0x50) {
      _frameBuffer.removeAt(0);
    }
  }
}

  void _parseFrame(List<int> data) {
    final screenBytes = data.sublist(0, 64);
    final status = data[64];
    final decoded = _decodeScreen(screenBytes);

    setState(() {
      lines = [
        decoded.substring(0, 16),
        decoded.substring(16, 32),
        decoded.substring(32, 48),
        decoded.substring(48, 64),
      ];

      ledLeft = (status & 0x02) != 0;
      ledRight = (status & 0x01) != 0;
      statusText = 'Terminal hazır';
    });

    // Frame geldi, artık yeni poll gönderebiliriz
    _pollInFlight = false;
    _waitingForFrameAfterKey = false;
    _suppressSingleByteEcho = false;

    Future.microtask(() async {
      await Future.delayed(const Duration(milliseconds: 150));
      await _sendIdlePoll();
    });
  }

  String _decodeScreen(List<int> bytes) {
    final chars = <String>[];

    for (final b in bytes) {
      final sb = b >= 128 ? b - 256 : b;

      switch (sb) {
        case 0:
          chars.add('↕');
          break;
        case 1:
          chars.add('↑');
          break;
        case 2:
          chars.add('↓');
          break;
        case -17:
          chars.add('ö');
          break;
        case -11:
          chars.add('ü');
          break;
        case -31:
          chars.add('ä');
          break;
        case -33:
          chars.add('°');
          break;
        default:
          if (b >= 32 && b <= 126) {
            chars.add(ascii.decode([b]));
          } else {
            chars.add(' ');
          }
      }
    }

    return chars.join().padRight(64).substring(0, 64);
  }

  Future<void> _sendKeyByte(int value) async {
    if (sessionState != DisplaySessionState.terminalReady) {
      _log('Key ignored, terminal not ready');
      return;
    }

    if (_waitingForFrameAfterKey) {
      _log('Previous key still waiting for next frame');
      return;
    }

    try {
      _waitingForFrameAfterKey = true;
      _pollInFlight = true;
      _suppressSingleByteEcho = true;

      await _writeBytes([value]);
      await Future.delayed(const Duration(milliseconds: 60));
    } catch (e) {
      _log('KEY SEND ERROR: $e');
      _waitingForFrameAfterKey = false;
      _pollInFlight = false;

      setState(() {
        statusText = 'Tuş gönderim hatası';
      });
    }
  }

  Future<void> _sendQuit() => _sendKeyByte(0xA7);
  Future<void> _sendAb() => _sendKeyByte(0xAB);
  Future<void> _sendAuf() => _sendKeyByte(0xAD);
  Future<void> _sendEnter() => _sendKeyByte(0xAE);

  Future<void> _sendMenu() => _sendKeyByte(0xA3);
  Future<void> _sendMonitor() => _sendKeyByte(0xA5);
  Future<void> _sendErrors() => _sendKeyByte(0xA6);

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
            color: onColor.withOpacity(0.65),
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
    width: 250,
    height: 162,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF0B4FA3),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.black, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Colors.black45,
          blurRadius: 8,
          offset: Offset(2, 4),
        ),
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
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
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
      return Scaffold(
        backgroundColor: const Color(0xFF202124),
        appBar: AppBar(
          title: const Text('FB10 Display'),
          backgroundColor: Colors.blueGrey,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 382,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F676D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black87, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16,
                      offset: Offset(4, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'ERROR',
                                style: TextStyle(
                                  color: Colors.white,
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
                              const Text(
                                'OPERATE',
                                style: TextStyle(
                                  color: Colors.white,
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
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buttonRow([
                      _button('Menu', _sendMenu),
                      _button('Monitor', _sendMonitor),
                      _button('Errors', _sendErrors),
                    ]),
                    const SizedBox(height: 10),
                    _buttonRow([
                      _button('QUIT', _sendQuit),
                      _button('AB', _sendAb),
                      _button('AUF', _sendAuf),
                      _button('ENTER', _sendEnter),
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
