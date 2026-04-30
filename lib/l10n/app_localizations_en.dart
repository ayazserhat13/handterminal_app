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
}
