import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'display_screen.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final List<ScanResult> _results = [];
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;

  bool _isScanning = false;
  String _status = 'Hazır';

  @override
  void initState() {
    super.initState();
    _listenScanResults();
    _listenScanState();
    _startScan();
  }

  void _listenScanResults() {
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;

      final Map<String, ScanResult> unique = {};
      for (final result in results) {
        unique[result.device.remoteId.str] = result;
      }

      final sorted = unique.values.toList()
        ..sort((a, b) {
          final aName = a.device.platformName.isNotEmpty
              ? a.device.platformName
              : 'Unknown Device';
          final bName = b.device.platformName.isNotEmpty
              ? b.device.platformName
              : 'Unknown Device';
          return aName.compareTo(bName);
        });

      setState(() {
        _results
          ..clear()
          ..addAll(sorted);
      });
    });
  }

  void _listenScanState() {
    _isScanningSub = FlutterBluePlus.isScanning.listen((value) {
      if (!mounted) return;
      setState(() {
        _isScanning = value;
        if (!value && _status == 'Taranıyor...') {
          _status = 'Tarama tamamlandı';
        }
      });
    });
  }

  Future<void> _startScan() async {
    try {
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) {
        setState(() {
          _status = 'Bu cihaz BLE desteklemiyor';
        });
        return;
      }

      setState(() {
        _status = 'Taranıyor...';
        _results.clear();
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    } catch (e) {
      setState(() {
        _status = 'Tarama hatası: $e';
      });
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      setState(() {
        _status = 'Tarama durduruldu';
      });
    } catch (e) {
      setState(() {
        _status = 'Durdurma hatası: $e';
      });
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _isScanningSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Bağlantısı'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            onPressed: _isScanning ? _stopScan : _startScan,
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.withOpacity(0.08),
            child: Text(_status),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Cihaz bulunamadı'))
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      final device = result.device;
                      final name = device.platformName.isNotEmpty
                          ? device.platformName
                          : 'Bilinmeyen Cihaz';

                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(name),
                        subtitle: Text(device.remoteId.str),
                        trailing: Text('RSSI ${result.rssi}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceDetailScreen(
                                device: device,
                                deviceName: name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? _stopScan : _startScan,
        icon: Icon(_isScanning ? Icons.stop : Icons.search),
        label: Text(_isScanning ? 'Durdur' : 'Tara'),
      ),
    );
  }
}

class DeviceDetailScreen extends StatefulWidget {
  final BluetoothDevice device;
  final String deviceName;

  const DeviceDetailScreen({
    super.key,
    required this.device,
    required this.deviceName,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;

  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;

  List<BluetoothService> _services = [];
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  String _log = '';
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _listenConnectionState();
    _connectAndDiscover();
  }

  void _listenConnectionState() {
    _connectionSub = widget.device.connectionState.listen((state) {
      if (!mounted) return;
      setState(() {
        _connectionState = state;
      });
      _appendLog('Durum: ${state.name}');
    });
  }

  void _appendLog(String text) {
    if (!mounted) return;
    setState(() {
      _log = '[$text]\n$_log';
    });
  }

  Future<void> _connectAndDiscover() async {
    setState(() {
      _isBusy = true;
    });

    try {
      _appendLog('Bağlanılıyor...');
      await widget.device.connect(timeout: const Duration(seconds: 10));
    } catch (_) {
      _appendLog('Cihaz zaten bağlı olabilir');
    }

    try {
      await _discoverServices();
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _discoverServices() async {
    _appendLog('Servisler taranıyor...');
    final services = await widget.device.discoverServices();

    BluetoothCharacteristic? writeChar;
    BluetoothCharacteristic? notifyChar;

    for (final service in services) {
      _appendLog('Service: ${service.uuid}');
      for (final characteristic in service.characteristics) {
        _appendLog(
          'Characteristic: ${characteristic.uuid} '
          'W:${characteristic.properties.write} '
          'WWR:${characteristic.properties.writeWithoutResponse} '
          'N:${characteristic.properties.notify} '
          'I:${characteristic.properties.indicate}',
        );

        if (writeChar == null &&
            (characteristic.properties.write ||
                characteristic.properties.writeWithoutResponse)) {
          writeChar = characteristic;
        }

        if (notifyChar == null &&
            (characteristic.properties.notify ||
                characteristic.properties.indicate)) {
          notifyChar = characteristic;
        }
      }
    }

    if (notifyChar != null) {
      await notifyChar.setNotifyValue(true);
      await _notifySub?.cancel();
      _notifySub = notifyChar.lastValueStream.listen((value) {
        _appendLog('RX HEX: ${_toHex(value)}');
        _appendLog('RX ASCII: ${_toAscii(value)}');
      });
    }

    setState(() {
      _services = services;
      _writeCharacteristic = writeChar;
      _notifyCharacteristic = notifyChar;
    });

    if (writeChar != null) {
      _appendLog('Yazma characteristic bulundu: ${writeChar.uuid}');
    } else {
      _appendLog('Yazma characteristic bulunamadı');
    }

    if (notifyChar != null) {
      _appendLog('Notify characteristic bulundu: ${notifyChar.uuid}');
    } else {
      _appendLog('Notify characteristic bulunamadı');
    }
  }

  Future<void> _sendTestPacket() async {
    final writeChar = _writeCharacteristic;
    if (writeChar == null) {
      _appendLog('Gönderim başarısız: write characteristic yok');
      return;
    }

    final bytes = <int>[127, 0, 0, 0, 0, 0, 0, 0];

    try {
      await writeChar.write(
        bytes,
        withoutResponse: writeChar.properties.writeWithoutResponse,
      );
      _appendLog('TX HEX: ${_toHex(bytes)}');
      _appendLog('TX ASCII: ${_toAscii(bytes)}');
    } catch (e) {
      _appendLog('Gönderim hatası: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      await _notifySub?.cancel();
      await widget.device.disconnect();
      _appendLog('Bağlantı kapatıldı');
    } catch (e) {
      _appendLog('Bağlantı kapatma hatası: $e');
    }
  }

  static String _toHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  static String _toAscii(List<int> bytes) {
    try {
      return ascii.decode(bytes, allowInvalid: true);
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _notifySub?.cancel();
    _connectionSub?.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected =
        _connectionState == BluetoothConnectionState.connected;

    final writeChar = _writeCharacteristic;
    final notifyChar = _notifyCharacteristic;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceName),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            onPressed: _disconnect,
            icon: const Icon(Icons.link_off),
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Cihaz'),
            subtitle: Text(widget.device.remoteId.str),
          ),
          ListTile(
            title: const Text('Durum'),
            subtitle: Text(_connectionState.name),
          ),
          ListTile(
            title: const Text('Write Characteristic'),
            subtitle: Text(writeChar?.uuid.toString() ?? 'Yok'),
          ),
          ListTile(
            title: const Text('Notify Characteristic'),
            subtitle: Text(notifyChar?.uuid.toString() ?? 'Yok'),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isBusy ? null : _discoverServices,
                        child: const Text('Servisleri Tara'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isConnected ? _sendTestPacket : null,
                        child: const Text('Test Paket Gönder'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_writeCharacteristic != null && _notifyCharacteristic != null)
                        ? () async {
                            final writeChar = _writeCharacteristic!;
                            final notifyChar = _notifyCharacteristic!;
                            await _notifySub?.cancel();
                            _notifySub = null;
                            
                            if (!context.mounted) return;
                            
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DisplayScreen(
                                  writeCharacteristic: writeChar,
                                  notifyCharacteristic: notifyChar,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: const Text('Display Aç'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  _log.isEmpty ? 'Log yok' : _log,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
          if (_services.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Henüz servis bulunmadı'),
            ),
        ],
      ),
    );
  }
}
