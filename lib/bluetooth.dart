import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handterminal_app/l10n/app_localizations.dart';

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
  String _status = ' ';

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

        final l10n = AppLocalizations.of(context)!;

        setState(() {
          _isScanning = value;
          if (!value && _status == l10n.bluetoothScanning) {
            _status = l10n.bluetoothScanComplete;
          }
        });
      });
  }

  Future<void> _startScan() async {
      final l10n = AppLocalizations.of(context)!;

      try {
        final supported = await FlutterBluePlus.isSupported;
        if (!supported) {
          setState(() {
            _status = l10n.bluetoothNotSupported;
          });
          return;
        }

        setState(() {
          _status = l10n.bluetoothScanning;
          _results.clear();
        });

        final adapterState = await FlutterBluePlus.adapterState
            .where((state) => state != BluetoothAdapterState.unknown)
            .first
            .timeout(const Duration(seconds: 3));

        if (adapterState != BluetoothAdapterState.on) {
          setState(() {
            _status = l10n.bluetoothTurnOnRequired;
          });
          return;
        }

        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
      } catch (e) {
        setState(() {
          _status = '${l10n.bluetoothScanError}: $e';
        });
      }
  }
  
  Future<void> _stopScan() async {
      final l10n = AppLocalizations.of(context)!;

      try {
        await FlutterBluePlus.stopScan();
        setState(() {
          _status = l10n.bluetoothStopped;
        });
      } catch (e) {
        setState(() {
          _status = '${l10n.bluetoothStopError}: $e';
        });
      }
  }
  
  IconData _signalIcon(int rssi) {
      if (rssi >= -55) return Icons.signal_cellular_4_bar;
      if (rssi >= -70) return Icons.signal_cellular_alt;
      if (rssi >= -85) return Icons.signal_cellular_alt_2_bar;
      return Icons.signal_cellular_alt_1_bar;
  }

  Color _signalColor(int rssi) {
      if (rssi >= -55) return Colors.green;
      if (rssi >= -70) return Colors.orange;
      return Colors.redAccent;
  }

  Future<void> _connectToDevice(
      BluetoothDevice device,
      String deviceName,
    ) async {
      final l10n = AppLocalizations.of(context)!;

      try {
        await FlutterBluePlus.stopScan();

        setState(() {
          _status = l10n.bluetoothConnecting(deviceName);
          _isScanning = false;
        });

        try {
          await device.connect(timeout: const Duration(seconds: 10));
        } catch (_) {
          // Device may already be connected.
        }

        final services = await device.discoverServices();

        BluetoothCharacteristic? writeChar;
        BluetoothCharacteristic? notifyChar;

        for (final service in services) {
          for (final characteristic in service.characteristics) {
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

        if (writeChar == null || notifyChar == null) {
          setState(() {
            _status = l10n.bluetoothMissingCharacteristics;
          });
          return;
        }

        await notifyChar.setNotifyValue(true);

        if (!mounted) return;

        Navigator.pop(context, {
          'device': device,
          'deviceName': deviceName,
          'writeCharacteristic': writeChar,
          'notifyCharacteristic': notifyChar,
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _status = '${l10n.bluetoothConnectionError}: $e';
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bluetoothTitle),
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
            child: Text(_status.isEmpty ? l10n.bluetoothReady : _status),
          ),
          Expanded(
            child: _results.isEmpty
                ? Center(child: Text(l10n.bluetoothNoDevicesFound))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final result = _results[index];
                final device = result.device;
                final name = device.platformName.isNotEmpty
                    ? device.platformName
                    : l10n.bluetoothUnknownDevice;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A4C93).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bluetooth,
                        color: Color(0xFF0A4C93),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        device.remoteId.str,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _signalIcon(result.rssi),
                          size: 22,
                          color: _signalColor(result.rssi),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${result.rssi} dBm',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await _connectToDevice(device, name);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? _stopScan : _startScan,
        icon: Icon(_isScanning ? Icons.stop : Icons.search),
        label: Text(_isScanning ? l10n.bluetoothStop : l10n.bluetoothScan),
      ),
    );
  }
}
