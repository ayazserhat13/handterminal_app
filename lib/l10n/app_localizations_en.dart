// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Handterminal App';

  @override
  String get screenTitle => 'TFT Display Simulation';

  @override
  String get menu => 'MENU';

  @override
  String get display => 'Display';

  @override
  String get graph => 'Graph';

  @override
  String get connection => 'Connection';

  @override
  String get settings => 'Settings';

  @override
  String get monitoring => 'Monitoring';

  @override
  String get errors => 'Errors';

  @override
  String get info => 'Info';

  @override
  String get quit => 'Quit';

  @override
  String get down => 'Down';

  @override
  String get up => 'Up';

  @override
  String get enter => 'Enter';

  @override
  String get lcdLineHello => 'Hello World!   ';

  @override
  String get lcdLineFloor => 'Floor: 3 Up    ';

  @override
  String get lcdLineReady => 'System Ready...';

  @override
  String get lcdLineNoError => 'No Error       ';

  @override
  String get fb10Display => 'FB10 Display';

  @override
  String get errorLed => 'ERROR';

  @override
  String get operateLed => 'OPERATE';

  @override
  String get monitor => 'Monitor';

  @override
  String get ab => 'DOWN';

  @override
  String get auf => 'UP';

  @override
  String get statusPreparingConnection => 'Preparing connection...';

  @override
  String get statusHandshakeStarting => 'Starting handshake...';

  @override
  String get statusWaitingForBb => 'Waiting for 0xBB...';

  @override
  String get statusFirstBbReceived => 'First 0xBB received, sending 0xAA...';

  @override
  String get statusSecondBbReceived =>
      'Second 0xBB received, starting terminal...';

  @override
  String get statusTerminalReady => 'Terminal ready';

  @override
  String get statusKeySendError => 'Key send error';

  @override
  String get statusBbTimeout => 'Timeout: 0xBB not received';

  @override
  String statusHandshakeError(Object error) {
    return 'Handshake error: $error';
  }

  @override
  String statusTerminalStartError(Object error) {
    return 'Terminal start error: $error';
  }

  @override
  String get homeConnect => 'Connect';

  @override
  String get homeTerminal => 'Terminal';

  @override
  String get homeSpeedCurve => 'Speed Curve';

  @override
  String get homeSoftwareUpdate => 'Software Update';

  @override
  String get homeDownloadErrors => 'Download Errors';

  @override
  String get homeDownloadParameters => 'Download Parameters';

  @override
  String get homeUploadParameters => 'Upload Parameters';

  @override
  String get homeDocuments => 'Documents';

  @override
  String get homeAbout => 'About';

  @override
  String get homeNotConnected => 'Not connected';

  @override
  String get homeConnectHint => 'Please connect to the device via Bluetooth.';

  @override
  String get bluetoothTitle => 'Bluetooth Connection';

  @override
  String get bluetoothReady => 'Ready';

  @override
  String get bluetoothScanning => 'Scanning for devices...';

  @override
  String get bluetoothScanComplete => 'Scan complete';

  @override
  String get bluetoothNoDevicesFound => 'No devices found';

  @override
  String get bluetoothUnknownDevice => 'Unknown Device';

  @override
  String get bluetoothScan => 'Scan';

  @override
  String get bluetoothStop => 'Stop';

  @override
  String get bluetoothNotSupported => 'This device does not support BLE';

  @override
  String get bluetoothScanError => 'Scan error';

  @override
  String get bluetoothStopError => 'Stop error';

  @override
  String get bluetoothStopped => 'Scan stopped';

  @override
  String bluetoothConnecting(Object deviceName) {
    return 'Connecting to $deviceName...';
  }

  @override
  String get bluetoothMissingCharacteristics =>
      'Connected, but required characteristics were not found';

  @override
  String get bluetoothConnectionError => 'Connection error';

  @override
  String get bluetoothConnectionLost => 'Bluetooth connection lost';

  @override
  String get bluetoothTurnOnRequired => 'Bluetooth must be turned on';

  @override
  String get bluetoothReconnecting => 'Reconnecting...';

  @override
  String get parametersTitle => 'Parameters';

  @override
  String get parameterExportSubtitle => 'FB10 parameter export';

  @override
  String get downloadedPackets => 'Downloaded packets';

  @override
  String get lastParameter => 'Last parameter';

  @override
  String get connectionReady => 'Ready';

  @override
  String get connectionWaiting => 'Waiting';

  @override
  String get export => 'Export';

  @override
  String get exportReady => 'Ready';

  @override
  String get exportPreparing => 'Preparing';

  @override
  String get txtExportReady => 'TXT Export Ready';

  @override
  String get exportDescription =>
      'Exported parameter file can be saved or shared.';

  @override
  String get saveTxt => 'Save TXT';

  @override
  String get preview => 'Preview';

  @override
  String get downloadProgress => 'Download progress';

  @override
  String parameterProgressValue(int current, int total) {
    return '$current / $total';
  }

  @override
  String percentComplete(int percent) {
    return '$percent%';
  }

  @override
  String get noParameter => '—';
}
