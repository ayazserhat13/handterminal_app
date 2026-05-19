import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:handterminal_app/core/ble/ble_characteristic_resolver.dart';
import 'package:handterminal_app/core/fb10/fb10_commands.dart';
import 'package:handterminal_app/core/fb10/fb10_write_queue.dart';
import 'package:handterminal_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'display_screen.dart';

import 'bluetooth.dart';
import 'graph_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _lastDeviceIdKey = 'last_connected_ble_device_id';
  static const String _lastDeviceNameKey = 'last_connected_ble_device_name';

  bool isReconnecting = false;
  bool _isAutoReconnecting = false;
  bool isConnected = false;

  BluetoothDevice? connectedDevice;
  String? connectedDeviceName;
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? notifyCharacteristic;

  bool _fb10Ready = false;
  int _handshakeTryCount = 0;
  Timer? _handshakeTimer;
  StreamSubscription<List<int>>? _fb10NotifySub;
  Fb10WriteQueue? _fb10WriteQueue;

  bool _blink = true;
  Timer? _blinkTimer;

  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  final BleCharacteristicResolver _characteristicResolver =
      const BleCharacteristicResolver();

  @override
  void initState() {
    super.initState();

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (!mounted) return;
      if (!isConnected) {
        setState(() => _blink = !_blink);
      }
    });

    Future.microtask(() {
      _autoReconnect();
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _connectionSub?.cancel();
    _cleanupFb10Session();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modeActionsEnabled = isConnected && _fb10Ready;

    return Scaffold(
      drawer: _HomeDrawer(
        modeActionsEnabled: modeActionsEnabled,
        onConnect: _openBluetooth,
      ),
      body: Stack(
        children: [
          const _AluminumBackground(),
          SafeArea(
            child: Stack(
              children: [
                _topBar(context, l10n),

                Positioned.fill(
                  top: 90,
                  bottom: 125,
                  child: Column(
                    children: [
                      const _BFLogo(width: 230),
                      const SizedBox(height: 34),
                      Expanded(
                        child: _ModernHomeMenu(
                          isConnected: isConnected,
                          modeActionsEnabled: modeActionsEnabled,
                          blink: _blink,
                          onConnect: _openBluetooth,
                          onTerminal: _openTerminalPlaceholder,
                          onSpeedCurve: _openGraph,
                          onSoftwareUpdate: _disabledAction,
                          onDownloadErrors: _disabledAction,
                          onDownloadParameters: _disabledAction,
                          onUploadParameters: _disabledAction,
                          onDocuments: _documentsAction,
                          onAbout: _aboutAction,
                        ),
                      ),
                    ],
                  ),
                ),

                _bottomStatus(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, AppLocalizations l10n) {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                color: const Color(0xFF0A4C93),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
          const Spacer(),
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: isConnected ? const Color(0xFF0A4C93) : Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _bottomStatus(AppLocalizations l10n) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isConnected
                ? ''
                : isReconnecting
                ? l10n.bluetoothReconnecting
                : l10n.homeNotConnected,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _startFb10Session({
    required BluetoothCharacteristic writeCharacteristic,
    required BluetoothCharacteristic notifyCharacteristic,
    bool initialReady = false,
  }) {
    _cleanupFb10Session();

    _fb10WriteQueue = Fb10WriteQueue(
      writer: (bytes) => _writeFb10Bytes(writeCharacteristic, bytes),
    );
    _fb10NotifySub = notifyCharacteristic.onValueReceived.listen(
      _handleFb10NotifyBytes,
    );

    _startFb10Handshake(initialReady: initialReady);
  }

  void _startFb10Handshake({required bool initialReady}) {
    final queue = _fb10WriteQueue;
    if (queue == null) return;

    _handshakeTimer?.cancel();
    queue.clearPending();

    _setFb10Ready(initialReady);
    _handshakeTryCount = 0;

    var sendWakeNext = true;

    if (initialReady) {
      debugPrint('HOME: restarting FB10 session in keepalive mode');
    } else {
      debugPrint('HOME: FB10 handshake start');
    }

    Future<void> sendNextSessionByte() async {
      if (_fb10WriteQueue != queue) return;
      if (!isConnected) return;
      if (queue.isBusy) return;

      if (_fb10Ready) {
        debugPrint('HOME: FB10 keepalive AA');

        try {
          await queue.enqueue(const [Fb10Commands.handshakeAck]);
        } catch (e) {
          debugPrint('HOME: FB10 keepalive write error: $e');
        }

        return;
      }

      final byteToSend = sendWakeNext
          ? Fb10Commands.handshakeWake
          : Fb10Commands.handshakeRequest;
      sendWakeNext = !sendWakeNext;
      _handshakeTryCount++;

      debugPrint(
        'HOME: FB10 handshake try $_handshakeTryCount byte ${_formatFb10Byte(byteToSend)}',
      );

      try {
        await queue.enqueue([byteToSend]);
      } catch (e) {
        debugPrint('HOME: FB10 handshake write error: $e');
      }
    }

    unawaited(sendNextSessionByte());
    _handshakeTimer = Timer.periodic(Fb10Timings.handshakeRetryInterval, (_) {
      unawaited(sendNextSessionByte());
    });
  }

  void _handleFb10NotifyBytes(List<int> value) {
    if (value.isEmpty) return;
    if (!value.contains(Fb10Commands.handshakeResponse)) return;

    debugPrint('HOME: FB10 RX contains BB');
    unawaited(_handleFb10HandshakeResponse());
  }

  Future<void> _handleFb10HandshakeResponse() async {
    final queue = _fb10WriteQueue;
    if (queue == null) return;

    queue.clearPending();

    try {
      await queue.enqueue(const [Fb10Commands.handshakeAck]);
    } catch (e) {
      debugPrint('HOME: FB10 handshake ack error: $e');
      return;
    }

    if (!mounted || _fb10WriteQueue != queue || !isConnected) return;

    if (!_fb10Ready) {
      _setFb10Ready(true);
      debugPrint('HOME: FB10 ready');
    }
  }

  void _setFb10Ready(bool ready) {
    if (_fb10Ready == ready) return;

    if (!mounted) {
      _fb10Ready = ready;
      return;
    }

    setState(() {
      _fb10Ready = ready;
    });
  }

  Future<void> _writeFb10Bytes(
    BluetoothCharacteristic characteristic,
    List<int> bytes,
  ) async {
    await characteristic.write(
      bytes,
      withoutResponse: characteristic.properties.writeWithoutResponse,
    );
  }

  void _cleanupFb10Session() {
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _fb10NotifySub?.cancel();
    _fb10NotifySub = null;
    _fb10WriteQueue?.close();
    _fb10WriteQueue = null;
    _fb10Ready = false;
    _handshakeTryCount = 0;
  }

  void _handoffFb10SessionToDisplayScreen() {
    debugPrint('HOME: FB10 session handoff to DisplayScreen');
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _fb10NotifySub?.cancel();
    _fb10NotifySub = null;
    _fb10WriteQueue?.close();
    _fb10WriteQueue = null;
    _handshakeTryCount = 0;
  }

  void _restartFb10SessionAfterDisplayScreen() {
    final currentWriteCharacteristic = writeCharacteristic;
    final currentNotifyCharacteristic = notifyCharacteristic;

    if (!mounted ||
        !isConnected ||
        connectedDevice == null ||
        currentWriteCharacteristic == null ||
        currentNotifyCharacteristic == null) {
      debugPrint('HOME: DisplayScreen returned; FB10 session restart skipped');
      return;
    }

    debugPrint('HOME: DisplayScreen returned; restarting FB10 session');
    _startFb10Session(
      writeCharacteristic: currentWriteCharacteristic,
      notifyCharacteristic: currentNotifyCharacteristic,
      initialReady: true,
    );
  }

  String _formatFb10Byte(int byte) {
    return '0x${byte.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  Future<void> _autoReconnect() async {
    if (_isAutoReconnecting) return;
    _isAutoReconnecting = true;
    setState(() {
      isReconnecting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDeviceId = prefs.getString(_lastDeviceIdKey);
      final lastDeviceName = prefs.getString(_lastDeviceNameKey);

      if (lastDeviceId == null) return;

      final supported = await FlutterBluePlus.isSupported;
      if (!supported) return;

      final adapterState = await FlutterBluePlus.adapterState
          .where((state) => state != BluetoothAdapterState.unknown)
          .first
          .timeout(const Duration(seconds: 3));

      if (adapterState != BluetoothAdapterState.on) return;

      BluetoothDevice? foundDevice;

      final scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          if (result.device.remoteId.str == lastDeviceId) {
            foundDevice = result.device;
            break;
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
      await Future.delayed(const Duration(seconds: 6));
      await FlutterBluePlus.stopScan();
      await scanSub.cancel();

      if (foundDevice == null) return;

      final device = foundDevice!;

      try {
        await device.connect(timeout: const Duration(seconds: 10));
      } catch (_) {
        // cihaz zaten bağlı olabilir
      }

      final services = await device.discoverServices();

      final characteristics = _characteristicResolver.resolve(services);

      if (characteristics == null) return;

      await characteristics.notifyCharacteristic.setNotifyValue(true);

      if (!mounted) return;

      setState(() {
        connectedDevice = device;
        connectedDeviceName = lastDeviceName;
        writeCharacteristic = characteristics.writeCharacteristic;
        notifyCharacteristic = characteristics.notifyCharacteristic;
        isConnected = true;
        _blink = false;
      });

      _startFb10Session(
        writeCharacteristic: characteristics.writeCharacteristic,
        notifyCharacteristic: characteristics.notifyCharacteristic,
      );

      _listenConnectionState(device);
    } catch (_) {
      // Kullanıcı manuel bağlanabilir.
    } finally {
      _isAutoReconnecting = false;

      if (mounted) {
        setState(() {
          isReconnecting = false;
        });
      }
    }
  }

  Future<void> _openBluetooth() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const BluetoothScreen()),
    );

    if (result == null) return;

    setState(() {
      connectedDevice = result['device'] as BluetoothDevice?;
      connectedDeviceName = result['deviceName'] as String?;
      writeCharacteristic =
          result['writeCharacteristic'] as BluetoothCharacteristic?;
      notifyCharacteristic =
          result['notifyCharacteristic'] as BluetoothCharacteristic?;

      isConnected =
          connectedDevice != null &&
          writeCharacteristic != null &&
          notifyCharacteristic != null;

      _blink = false;
    });

    final device = connectedDevice;
    final currentWriteCharacteristic = writeCharacteristic;
    final currentNotifyCharacteristic = notifyCharacteristic;

    if (currentWriteCharacteristic != null &&
        currentNotifyCharacteristic != null) {
      _startFb10Session(
        writeCharacteristic: currentWriteCharacteristic,
        notifyCharacteristic: currentNotifyCharacteristic,
      );
    }

    if (device != null) {
      _listenConnectionState(device);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastDeviceIdKey, device.remoteId.str);

      if (connectedDeviceName != null) {
        await prefs.setString(_lastDeviceNameKey, connectedDeviceName!);
      }
    }
  }

  void _listenConnectionState(BluetoothDevice device) {
    _connectionSub?.cancel();

    _connectionSub = device.connectionState.listen((state) {
      if (!mounted) return;

      if (state == BluetoothConnectionState.disconnected) {
        final l10n = AppLocalizations.of(context)!;

        _cleanupFb10Session();

        setState(() {
          isConnected = false;
          connectedDevice = null;
          connectedDeviceName = null;
          writeCharacteristic = null;
          notifyCharacteristic = null;
          _blink = true;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.bluetoothConnectionLost)));

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          if (!isConnected) {
            _autoReconnect();
          }
        });
      }
    });
  }

  void _openGraph() {
    if (!isConnected || !_fb10Ready) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GraphScreen()),
    );
  }

  Future<void> _openTerminalPlaceholder() async {
    if (!isConnected ||
        connectedDevice == null ||
        writeCharacteristic == null ||
        notifyCharacteristic == null) {
      return;
    }

    if (!_fb10Ready) {
      debugPrint('HOME: Terminal open blocked; fb10Ready=false');
      return;
    }

    final terminalWriteCharacteristic = writeCharacteristic!;
    final terminalNotifyCharacteristic = notifyCharacteristic!;

    _handoffFb10SessionToDisplayScreen();

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.35),
        pageBuilder: (_, __, ___) => DisplayScreen(
          writeCharacteristic: terminalWriteCharacteristic,
          notifyCharacteristic: terminalNotifyCharacteristic,
        ),
      ),
    );

    _restartFb10SessionAfterDisplayScreen();
  }

  void _disabledAction() {
    if (!isConnected || !_fb10Ready) return;
  }

  void _documentsAction() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Documents')));
  }

  void _aboutAction() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('About')));
  }
}

class _AluminumBackground extends StatelessWidget {
  const _AluminumBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF2F2F2),
            Color(0xFFD2D5D8),
            Color(0xFFE8E8E8),
            Color(0xFFC9CDD1),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _BrushedMetalPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BrushedMetalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..strokeWidth = 0.7;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircularHomeMenu extends StatelessWidget {
  final bool isConnected;
  final bool modeActionsEnabled;
  final bool blink;

  final VoidCallback onConnect;
  final VoidCallback onTerminal;
  final VoidCallback onSpeedCurve;
  final VoidCallback onSoftwareUpdate;
  final VoidCallback onDownloadErrors;
  final VoidCallback onDownloadParameters;
  final VoidCallback onUploadParameters;
  final VoidCallback onDocuments;
  final VoidCallback onAbout;

  const _CircularHomeMenu({
    required this.isConnected,
    required this.modeActionsEnabled,
    required this.blink,
    required this.onConnect,
    required this.onTerminal,
    required this.onSpeedCurve,
    required this.onSoftwareUpdate,
    required this.onDownloadErrors,
    required this.onDownloadParameters,
    required this.onUploadParameters,
    required this.onDocuments,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    const size = 330.0;
    const radius = 122.0;

    final items = [
      _HomeMenuItem(
        angle: -90,
        icon: Icons.bluetooth,
        label: l10n.homeConnect,
        enabled: true,
        blink: !isConnected,
        onTap: onConnect,
      ),
      _HomeMenuItem(
        angle: -45,
        icon: Icons.terminal,
        label: l10n.homeTerminal,
        enabled: modeActionsEnabled,
        onTap: onTerminal,
      ),
      _HomeMenuItem(
        angle: 0,
        icon: Icons.speed,
        label: l10n.homeSpeedCurve,
        enabled: modeActionsEnabled,
        onTap: onSpeedCurve,
      ),
      _HomeMenuItem(
        angle: 45,
        icon: Icons.system_update_alt,
        label: l10n.homeSoftwareUpdate,
        enabled: modeActionsEnabled,
        onTap: onSoftwareUpdate,
      ),
      _HomeMenuItem(
        angle: 90,
        icon: Icons.error_outline,
        label: l10n.homeDownloadErrors,
        enabled: modeActionsEnabled,
        onTap: onDownloadErrors,
      ),
      _HomeMenuItem(
        angle: 135,
        icon: Icons.download,
        label: l10n.homeDownloadParameters,
        enabled: modeActionsEnabled,
        onTap: onDownloadParameters,
      ),
      _HomeMenuItem(
        angle: 180,
        icon: Icons.upload,
        label: l10n.homeUploadParameters,
        enabled: modeActionsEnabled,
        onTap: onUploadParameters,
      ),
      _HomeMenuItem(
        angle: 225,
        icon: Icons.description_outlined,
        label: l10n.homeDocuments,
        enabled: true,
        onTap: onDocuments,
      ),
      _HomeMenuItem(
        angle: 270,
        icon: Icons.info_outline,
        label: l10n.homeAbout,
        enabled: true,
        onTap: onAbout,
      ),
    ];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 265,
            height: 265,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0A4C93).withOpacity(0.22),
                width: 2,
              ),
            ),
          ),
          _centerLogo(),
          ...items.map((item) {
            final rad = item.angle * pi / 180.0;
            final x = cos(rad) * radius;
            final y = sin(rad) * radius;

            return Transform.translate(
              offset: Offset(x, y),
              child: _RoundMenuButton(
                icon: item.icon,
                label: item.label,
                enabled: item.enabled,
                blink: item.blink && blink,
                onTap: item.onTap,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _centerLogo() {
    return const _BFLogo(width: 170);
  }
}

class _ModernHomeMenu extends StatelessWidget {
  final bool isConnected;
  final bool modeActionsEnabled;
  final bool blink;

  final VoidCallback onConnect;
  final VoidCallback onTerminal;
  final VoidCallback onSpeedCurve;
  final VoidCallback onSoftwareUpdate;
  final VoidCallback onDownloadErrors;
  final VoidCallback onDownloadParameters;
  final VoidCallback onUploadParameters;
  final VoidCallback onDocuments;
  final VoidCallback onAbout;

  const _ModernHomeMenu({
    required this.isConnected,
    required this.modeActionsEnabled,
    required this.blink,
    required this.onConnect,
    required this.onTerminal,
    required this.onSpeedCurve,
    required this.onSoftwareUpdate,
    required this.onDownloadErrors,
    required this.onDownloadParameters,
    required this.onUploadParameters,
    required this.onDocuments,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            const _FlowLine(top: 70),
            const _FlowLine(top: 275, reverse: true),

            _pos(
              w * 0.07,
              h * 0.02,
              _ModernMenuButton(
                icon: Icons.bluetooth,
                label: l10n.homeConnect,
                enabled: true,
                primary: true,
                blink: !isConnected && blink,
                onTap: onConnect,
              ),
            ),

            _pos(
              w * 0.61,
              h * 0.06,
              _ModernMenuButton(
                icon: Icons.terminal,
                label: l10n.homeTerminal,
                enabled: modeActionsEnabled,
                onTap: onTerminal,
              ),
            ),

            _pos(
              w * 0.36,
              h * 0.23,
              _ModernMenuButton(
                icon: Icons.speed,
                label: l10n.homeSpeedCurve,
                enabled: modeActionsEnabled,
                onTap: onSpeedCurve,
              ),
            ),

            _pos(
              w * 0.12,
              h * 0.30,
              _ModernMenuButton(
                icon: Icons.description_outlined,
                label: l10n.homeDocuments,
                enabled: true,
                onTap: onDocuments,
              ),
            ),

            _pos(
              w * 0.68,
              h * 0.34,
              _ModernMenuButton(
                icon: Icons.download,
                label: l10n.homeDownloadParameters,
                enabled: modeActionsEnabled,
                onTap: onDownloadParameters,
              ),
            ),

            _pos(
              w * 0.12,
              h * 0.54,
              _ModernMenuButton(
                icon: Icons.upload,
                label: l10n.homeUploadParameters,
                enabled: modeActionsEnabled,
                onTap: onUploadParameters,
              ),
            ),

            _pos(
              w * 0.41,
              h * 0.52,
              _ModernMenuButton(
                icon: Icons.error_outline,
                label: l10n.homeDownloadErrors,
                enabled: modeActionsEnabled,
                onTap: onDownloadErrors,
              ),
            ),

            _pos(
              w * 0.68,
              h * 0.58,
              _ModernMenuButton(
                icon: Icons.system_update_alt,
                label: l10n.homeSoftwareUpdate,
                enabled: modeActionsEnabled,
                onTap: onSoftwareUpdate,
              ),
            ),

            _pos(
              w * 0.32,
              h * 0.78,
              _ModernMenuButton(
                icon: Icons.info_outline,
                label: l10n.homeAbout,
                enabled: true,
                onTap: onAbout,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pos(double left, double top, Widget child) {
    return Positioned(left: left, top: top, child: child);
  }
}

class _BFLogo extends StatelessWidget {
  final double width;

  const _BFLogo({required this.width});

  static const blue = Color(0xFF0A4C93);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: const [
                    Text(
                      'B',
                      style: TextStyle(
                        fontSize: 70,
                        height: 0.85,
                        fontWeight: FontWeight.w900,
                        color: blue,
                      ),
                    ),
                    Positioned(
                      left: 6,
                      top: 14,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Brunner',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  '&',
                  style: TextStyle(
                    fontSize: 48,
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                    color: blue,
                  ),
                ),
                Stack(
                  alignment: Alignment.centerLeft,
                  children: const [
                    Text(
                      'F',
                      style: TextStyle(
                        fontSize: 70,
                        height: 0.85,
                        fontWeight: FontWeight.w900,
                        color: blue,
                      ),
                    ),
                    Positioned(
                      left: 6,
                      top: 18,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          'Fecher',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(height: 3, color: blue),
            const SizedBox(height: 2),
            const Text(
              'Motion Control',
              style: TextStyle(
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w800,
                color: blue,
                letterSpacing: 0.5,
              ),
            ),
            Container(height: 3, color: blue),
          ],
        ),
      ),
    );
  }
}

class _HomeMenuItem {
  final double angle;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool blink;
  final VoidCallback onTap;

  const _HomeMenuItem({
    required this.angle,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.blink = false,
  });
}

class _RoundMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool blink;
  final VoidCallback onTap;

  const _RoundMenuButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.blink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF0A4C93);
    final inactiveColor = const Color(0xFF0A4C93).withOpacity(0.28);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: blink ? 1.0 : 0.45,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled
                      ? [activeColor.withOpacity(0.95), const Color(0xFF063466)]
                      : [inactiveColor, inactiveColor.withOpacity(0.55)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: enabled
                        ? activeColor.withOpacity(0.32)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: enabled ? 14 : 5,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: enabled ? Colors.white : Colors.white.withOpacity(0.55),
                size: 29,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 88,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled ? Colors.black87 : Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool primary;
  final bool blink;
  final VoidCallback onTap;

  const _ModernMenuButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.primary = false,
    this.blink = false,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0A4C93);

    final double size = primary ? 100 : 82;
    final double iconSize = primary ? 36 : 30;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 350),
        opacity: enabled ? (blink ? 1.0 : 0.72) : 0.36,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFE7ECEF)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 8,
                offset: const Offset(-3, -3),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(6, 8),
              ),
              if (primary)
                BoxShadow(
                  color: blue.withOpacity(0.35),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: enabled || primary ? blue : Colors.black38,
                  size: iconSize,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled || primary ? Colors.black87 : Colors.black38,
                    fontSize: primary ? 12 : 11,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowLine extends StatelessWidget {
  final double top;
  final bool reverse;

  const _FlowLine({required this.top, this.reverse = false});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -80,
      right: -80,
      top: top,
      child: Transform.scale(
        scaleX: reverse ? -1 : 1,
        child: CustomPaint(
          size: const Size(double.infinity, 120),
          painter: _FlowLinePainter(),
        ),
      ),
    );
  }
}

class _FlowLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0A4C93).withOpacity(0.18)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.05,
        size.width * 0.58,
        size.height * 1.05,
        size.width,
        size.height * 0.25,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeDrawer extends StatelessWidget {
  final bool modeActionsEnabled;
  final VoidCallback onConnect;

  const _HomeDrawer({
    required this.modeActionsEnabled,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: const Color(0xFFE1E3E5),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: _BFLogo(width: 170),
            ),
            const SizedBox(height: 18),
            _drawerItem(
              context,
              icon: Icons.bluetooth,
              title: l10n.homeConnect,
              enabled: true,
              onTap: onConnect,
            ),
            _drawerItem(
              context,
              icon: Icons.terminal,
              title: l10n.homeTerminal,
              enabled: modeActionsEnabled,
              onTap: () {},
            ),
            _drawerItem(
              context,
              icon: Icons.speed,
              title: l10n.homeSpeedCurve,
              enabled: modeActionsEnabled,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GraphScreen()),
                );
              },
            ),
            _drawerItem(
              context,
              icon: Icons.system_update_alt,
              title: l10n.homeSoftwareUpdate,
              enabled: modeActionsEnabled,
              onTap: () {},
            ),
            _drawerItem(
              context,
              icon: Icons.error_outline,
              title: l10n.homeDownloadErrors,
              enabled: modeActionsEnabled,
              onTap: () {},
            ),
            _drawerItem(
              context,
              icon: Icons.download,
              title: l10n.homeDownloadParameters,
              enabled: modeActionsEnabled,
              onTap: () {},
            ),
            _drawerItem(
              context,
              icon: Icons.upload,
              title: l10n.homeUploadParameters,
              enabled: modeActionsEnabled,
              onTap: () {},
            ),
            const Divider(),
            _drawerItem(
              context,
              icon: Icons.description_outlined,
              title: l10n.homeDocuments,
              enabled: true,
              onTap: () {},
            ),
            _drawerItem(
              context,
              icon: Icons.info_outline,
              title: l10n.homeAbout,
              enabled: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return ListTile(
      enabled: enabled,
      leading: Icon(
        icon,
        color: enabled ? const Color(0xFF0A4C93) : Colors.black26,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.black38,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: enabled
          ? () {
              Navigator.pop(context);
              onTap();
            }
          : null,
    );
  }
}
