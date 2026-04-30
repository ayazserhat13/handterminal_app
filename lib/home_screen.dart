import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:handterminal_app/l10n/app_localizations.dart';

import 'bluetooth.dart';
import 'graph_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isConnected = false;
  bool _blink = true;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (!mounted) return;
      if (!isConnected) {
        setState(() => _blink = !_blink);
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: _HomeDrawer(
        isConnected: isConnected,
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
            isConnected ? '' : l10n.homeNotConnected,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!isConnected) const SizedBox(height: 6),
          if (!isConnected)
            Text(
              l10n.homeConnectHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  void _openBluetooth() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BluetoothScreen(),
      ),
    );
  }

  void _openGraph() {
    if (!isConnected) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GraphScreen(),
      ),
    );
  }

  void _openTerminalPlaceholder() {
    if (!isConnected) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terminal screen will be connected here.')),
    );
  }

  void _disabledAction() {
    if (!isConnected) return;
  }

  void _documentsAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Documents')),
    );
  }

  void _aboutAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('About')),
    );
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
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CircularHomeMenu extends StatelessWidget {
  final bool isConnected;
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
        enabled: isConnected,
        onTap: onTerminal,
      ),
      _HomeMenuItem(
        angle: 0,
        icon: Icons.speed,
        label: l10n.homeSpeedCurve,
        enabled: isConnected,
        onTap: onSpeedCurve,
      ),
      _HomeMenuItem(
        angle: 45,
        icon: Icons.system_update_alt,
        label: l10n.homeSoftwareUpdate,
        enabled: isConnected,
        onTap: onSoftwareUpdate,
      ),
      _HomeMenuItem(
        angle: 90,
        icon: Icons.error_outline,
        label: l10n.homeDownloadErrors,
        enabled: isConnected,
        onTap: onDownloadErrors,
      ),
      _HomeMenuItem(
        angle: 135,
        icon: Icons.download,
        label: l10n.homeDownloadParameters,
        enabled: isConnected,
        onTap: onDownloadParameters,
      ),
      _HomeMenuItem(
        angle: 180,
        icon: Icons.upload,
        label: l10n.homeUploadParameters,
        enabled: isConnected,
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
                enabled: isConnected,
                onTap: onTerminal,
              ),
            ),

            _pos(
              w * 0.36,
              h * 0.23,
              _ModernMenuButton(
                icon: Icons.speed,
                label: l10n.homeSpeedCurve,
                enabled: isConnected,
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
                enabled: isConnected,
                onTap: onDownloadParameters,
              ),
            ),

            _pos(
              w * 0.12,
              h * 0.54,
              _ModernMenuButton(
                icon: Icons.upload,
                label: l10n.homeUploadParameters,
                enabled: isConnected,
                onTap: onUploadParameters,
              ),
            ),

            _pos(
              w * 0.41,
              h * 0.52,
              _ModernMenuButton(
                icon: Icons.error_outline,
                label: l10n.homeDownloadErrors,
                enabled: isConnected,
                onTap: onDownloadErrors,
              ),
            ),

            _pos(
              w * 0.68,
              h * 0.58,
              _ModernMenuButton(
                icon: Icons.system_update_alt,
                label: l10n.homeSoftwareUpdate,
                enabled: isConnected,
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
    return Positioned(
      left: left,
      top: top,
      child: child,
    );
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
                      ? [
                          activeColor.withOpacity(0.95),
                          const Color(0xFF063466),
                        ]
                      : [
                          inactiveColor,
                          inactiveColor.withOpacity(0.55),
                        ],
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
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFE7ECEF),
              ],
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

  const _FlowLine({
    required this.top,
    this.reverse = false,
  });

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
  final bool isConnected;
  final VoidCallback onConnect;

  const _HomeDrawer({
    required this.isConnected,
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const _BFLogo(width: 170),
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
              enabled: isConnected,
              onTap: () {},
            ),
            _drawerItem(
              context,
              icon: Icons.speed,
              title: l10n.homeSpeedCurve,
              enabled: isConnected,
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
              enabled: isConnected,
              onTap: () {},
            ),
            _drawerItem(
              context,
              icon: Icons.error_outline,
              title: l10n.homeDownloadErrors,
              enabled: isConnected,
              onTap: () {},
            ),
            _drawerItem(
              context,
              icon: Icons.download,
              title: l10n.homeDownloadParameters,
              enabled: isConnected,
              onTap: () {},
            ),
            _drawerItem(
              context,
              icon: Icons.upload,
              title: l10n.homeUploadParameters,
              enabled: isConnected,
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
