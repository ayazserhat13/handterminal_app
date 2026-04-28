import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:handterminal_app/l10n/app_localizations.dart';

import 'bluetooth.dart';
import 'graph_screen.dart';
import 'splash_screen.dart';

void main() {
  runApp(const LcdApp());
}

class LcdApp extends StatelessWidget {
  const LcdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
        Locale('fr'),
        Locale('nl'),
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale == null) {
          return const Locale('en');
        }

        for (var locale in supportedLocales) {
          if (locale.languageCode == deviceLocale.languageCode) {
            return locale;
          }
        }

        return const Locale('en');
      },
      home: const SplashScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  List<String> _lcdLines(AppLocalizations l10n) {
    return [
      l10n.lcdLineHello,
      l10n.lcdLineFloor,
      l10n.lcdLineReady,
      l10n.lcdLineNoError,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.screenTitle),
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LCDScreen(lines: _lcdLines(l10n)),
            const SizedBox(height: 20),
            const ButtonRow(),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: Colors.blueGrey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black87),
            child: Text(
              l10n.menu,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Courier',
              ),
            ),
          ),
          MenuItem(
            title: l10n.display,
            icon: Icons.desktop_windows,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          MenuItem(
            title: l10n.graph,
            icon: Icons.show_chart,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GraphScreen(),
                ),
              );
            },
          ),
          MenuItem(
            title: l10n.connection,
            icon: Icons.bluetooth,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BluetoothScreen(),
                ),
              );
            },
          ),
          MenuItem(
            title: l10n.settings,
            icon: Icons.settings,
            onTap: () {
              Navigator.pop(context);
              debugPrint('Settings selected');
            },
          ),
          MenuItem(
            title: l10n.monitoring,
            icon: Icons.visibility,
            onTap: () {
              Navigator.pop(context);
              debugPrint('Monitoring selected');
            },
          ),
          MenuItem(
            title: l10n.errors,
            icon: Icons.error,
            onTap: () {
              Navigator.pop(context);
              debugPrint('Errors selected');
            },
          ),
          MenuItem(
            title: l10n.info,
            icon: Icons.info,
            onTap: () {
              Navigator.pop(context);
              debugPrint('Info selected');
            },
          ),
        ],
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Courier',
        ),
      ),
      onTap: onTap,
    );
  }
}

class LCDScreen extends StatelessWidget {
  final List<String> lines;

  const LCDScreen({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      height: 128,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: lines.map((line) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              line,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
                fontSize: 24,
                height: 1.3,
                letterSpacing: 0.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ButtonRow extends StatelessWidget {
  const ButtonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PushButton(
          label: l10n.quit,
          onPressed: () => debugPrint('Quit pressed'),
        ),
        const SizedBox(width: 12),
        PushButton(
          label: l10n.down,
          onPressed: () => debugPrint('Down pressed'),
        ),
        const SizedBox(width: 12),
        PushButton(
          label: l10n.up,
          onPressed: () => debugPrint('Up pressed'),
        ),
        const SizedBox(width: 12),
        PushButton(
          label: l10n.enter,
          onPressed: () => debugPrint('Enter pressed'),
        ),
      ],
    );
  }
}

class PushButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PushButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
