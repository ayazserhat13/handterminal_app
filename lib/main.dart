import 'package:flutter/material.dart';
import 'bluetooth.dart';
import 'graph_screen.dart';

void main() {
  runApp(const LcdApp());
}

class LcdApp extends StatelessWidget {
  const LcdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Handterminal App',
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const List<String> lcdLines = [
    'Merhaba Dünya!  ',
    'Kat: 3 Yukarı   ',
    'Sistem Hazır... ',
    'Hata Yok        ',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('TFT Ekran Simülasyonu'),
        backgroundColor: Colors.blueGrey,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LCDScreen(lines: lcdLines),
            SizedBox(height: 20),
            ButtonRow(),
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
    return Drawer(
      backgroundColor: Colors.blueGrey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black87),
            child: Text(
              'MENÜ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Courier',
              ),
            ),
          ),
          MenuItem(
            title: 'Display',
            icon: Icons.desktop_windows,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          MenuItem(
            title: 'Grafik',
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
            title: 'Bağlantı',
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
            title: 'Ayarlar',
            icon: Icons.settings,
            onTap: () {
              Navigator.pop(context);
              debugPrint('Ayarlar seçildi');
            },
          ),
          MenuItem(
            title: 'İzleme',
            icon: Icons.visibility,
            onTap: () {
              Navigator.pop(context);
              debugPrint('İzleme seçildi');
            },
          ),
          MenuItem(
            title: 'Hatalar',
            icon: Icons.error,
            onTap: () {
              Navigator.pop(context);
              debugPrint('Hatalar seçildi');
            },
          ),
          MenuItem(
            title: 'Info',
            icon: Icons.info,
            onTap: () {
              Navigator.pop(context);
              debugPrint('Info seçildi');
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PushButton(
          label: 'Quit',
          onPressed: () => debugPrint('Quit basıldı'),
        ),
        const SizedBox(width: 12),
        PushButton(
          label: 'Down',
          onPressed: () => debugPrint('Down basıldı'),
        ),
        const SizedBox(width: 12),
        PushButton(
          label: 'Up',
          onPressed: () => debugPrint('Up basıldı'),
        ),
        const SizedBox(width: 12),
        PushButton(
          label: 'Enter',
          onPressed: () => debugPrint('Enter basıldı'),
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