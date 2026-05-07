import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleCharacteristicPair {
  final BluetoothCharacteristic writeCharacteristic;
  final BluetoothCharacteristic notifyCharacteristic;

  const BleCharacteristicPair({
    required this.writeCharacteristic,
    required this.notifyCharacteristic,
  });
}

class BleCharacteristicResolver {
  const BleCharacteristicResolver();

  BleCharacteristicPair? resolve(List<BluetoothService> services) {
    BluetoothCharacteristic? writeCharacteristic;
    BluetoothCharacteristic? notifyCharacteristic;

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (writeCharacteristic == null &&
            (characteristic.properties.write ||
                characteristic.properties.writeWithoutResponse)) {
          writeCharacteristic = characteristic;
        }

        if (notifyCharacteristic == null &&
            (characteristic.properties.notify ||
                characteristic.properties.indicate)) {
          notifyCharacteristic = characteristic;
        }
      }
    }

    if (writeCharacteristic == null || notifyCharacteristic == null) {
      return null;
    }

    return BleCharacteristicPair(
      writeCharacteristic: writeCharacteristic,
      notifyCharacteristic: notifyCharacteristic,
    );
  }
}
