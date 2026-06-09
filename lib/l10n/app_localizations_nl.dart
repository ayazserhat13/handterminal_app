// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Handterminal App';

  @override
  String get screenTitle => 'TFT-schermsimulatie';

  @override
  String get menu => 'MENU';

  @override
  String get display => 'Display';

  @override
  String get graph => 'Grafiek';

  @override
  String get connection => 'Verbinding';

  @override
  String get settings => 'Instellingen';

  @override
  String get monitoring => 'Monitoring';

  @override
  String get errors => 'Fouten';

  @override
  String get info => 'Info';

  @override
  String get quit => 'Quit';

  @override
  String get down => 'Omlaag';

  @override
  String get up => 'Omhoog';

  @override
  String get enter => 'Enter';

  @override
  String get lcdLineHello => 'Hallo Wereld!  ';

  @override
  String get lcdLineFloor => 'Verdieping: 3 ↑ ';

  @override
  String get lcdLineReady => 'Systeem gereed.';

  @override
  String get lcdLineNoError => 'Geen fout      ';

  @override
  String get fb10Display => 'FB10-display';

  @override
  String get errorLed => 'FOUT';

  @override
  String get operateLed => 'BEDRIJF';

  @override
  String get monitor => 'Monitor';

  @override
  String get ab => 'OMLAAG';

  @override
  String get auf => 'OMHOOG';

  @override
  String get statusPreparingConnection => 'Verbinding wordt voorbereid...';

  @override
  String get statusHandshakeStarting => 'Handshake wordt gestart...';

  @override
  String get statusWaitingForBb => 'Wachten op 0xBB...';

  @override
  String get statusFirstBbReceived =>
      'Eerste 0xBB ontvangen, 0xAA wordt verzonden...';

  @override
  String get statusSecondBbReceived =>
      'Tweede 0xBB ontvangen, terminal wordt gestart...';

  @override
  String get statusTerminalReady => 'Terminal gereed';

  @override
  String get statusKeySendError => 'Fout bij verzenden van toets';

  @override
  String get statusBbTimeout => 'Timeout: 0xBB niet ontvangen';

  @override
  String statusHandshakeError(Object error) {
    return 'Handshake-fout: $error';
  }

  @override
  String statusTerminalStartError(Object error) {
    return 'Fout bij starten van terminal: $error';
  }

  @override
  String get homeConnect => 'Verbinden';

  @override
  String get homeTerminal => 'Terminal';

  @override
  String get homeSpeedCurve => 'Snelheidscurve';

  @override
  String get homeSoftwareUpdate => 'Software-update';

  @override
  String get homeDownloadErrors => 'Fouten downloaden';

  @override
  String get homeDownloadParameters => 'Parameters downloaden';

  @override
  String get homeUploadParameters => 'Parameters uploaden';

  @override
  String get homeDocuments => 'Documenten';

  @override
  String get homeAbout => 'Info';

  @override
  String get homeNotConnected => 'Niet verbonden';

  @override
  String get homeConnectHint =>
      'Maak verbinding met het apparaat via Bluetooth.';

  @override
  String get bluetoothTitle => 'Bluetooth-verbinding';

  @override
  String get bluetoothReady => 'Gereed';

  @override
  String get bluetoothScanning => 'Apparaten zoeken...';

  @override
  String get bluetoothScanComplete => 'Zoeken voltooid';

  @override
  String get bluetoothNoDevicesFound => 'Geen apparaten gevonden';

  @override
  String get bluetoothUnknownDevice => 'Onbekend apparaat';

  @override
  String get bluetoothScan => 'Zoeken';

  @override
  String get bluetoothStop => 'Stoppen';

  @override
  String get bluetoothNotSupported => 'Dit apparaat ondersteunt geen BLE';

  @override
  String get bluetoothScanError => 'Fout bij zoeken';

  @override
  String get bluetoothStopError => 'Fout bij stoppen';

  @override
  String get bluetoothStopped => 'Zoeken gestopt';

  @override
  String bluetoothConnecting(Object deviceName) {
    return 'Verbinding maken met $deviceName...';
  }

  @override
  String get bluetoothMissingCharacteristics =>
      'Verbonden, maar vereiste kenmerken zijn niet gevonden';

  @override
  String get bluetoothConnectionError => 'Verbindingsfout';

  @override
  String get bluetoothConnectionLost => 'Bluetooth-verbinding verbroken';

  @override
  String get bluetoothTurnOnRequired => 'Bluetooth moet ingeschakeld zijn';

  @override
  String get bluetoothReconnecting => 'Opnieuw verbinden...';

  @override
  String get parametersTitle => 'Parameterexport';

  @override
  String get parameterExportSubtitle => 'FB10-parameterexport';

  @override
  String get downloadedPackets => 'Gedownloade pakketten';

  @override
  String get lastParameter => 'Laatste parameter';

  @override
  String get connectionReady => 'Gereed';

  @override
  String get connectionWaiting => 'Wachten';

  @override
  String get export => 'Exporteren';

  @override
  String get exportReady => 'Gereed';

  @override
  String get exportPreparing => 'Voorbereiden';

  @override
  String get txtExportReady => 'TXT-export gereed';

  @override
  String get exportDescription =>
      'Het geëxporteerde parameterbestand kan worden opgeslagen of gedeeld.';

  @override
  String get saveTxt => 'TXT opslaan';

  @override
  String get preview => 'Voorbeeld';

  @override
  String get downloadProgress => 'Downloadvoortgang';

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
