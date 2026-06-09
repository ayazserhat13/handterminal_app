// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Handterminal App';

  @override
  String get screenTitle => 'TFT Display Simulation';

  @override
  String get menu => 'MENÜ';

  @override
  String get display => 'Display';

  @override
  String get graph => 'Grafik';

  @override
  String get connection => 'Verbindung';

  @override
  String get settings => 'Einstellungen';

  @override
  String get monitoring => 'Überwachung';

  @override
  String get errors => 'Fehler';

  @override
  String get info => 'Info';

  @override
  String get quit => 'Quit';

  @override
  String get down => 'Runter';

  @override
  String get up => 'Hoch';

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
  String get errorLed => 'FEHLER';

  @override
  String get operateLed => 'BETRIEB';

  @override
  String get monitor => 'Monitor';

  @override
  String get ab => 'AB';

  @override
  String get auf => 'AUF';

  @override
  String get statusPreparingConnection => 'Verbindung wird vorbereitet...';

  @override
  String get statusHandshakeStarting => 'Handshake wird gestartet...';

  @override
  String get statusWaitingForBb => 'Warte auf 0xBB...';

  @override
  String get statusFirstBbReceived =>
      'Erstes 0xBB empfangen, 0xAA wird gesendet...';

  @override
  String get statusSecondBbReceived =>
      'Zweites 0xBB empfangen, Terminal wird gestartet...';

  @override
  String get statusTerminalReady => 'Terminal bereit';

  @override
  String get statusKeySendError => 'Fehler beim Senden der Taste';

  @override
  String get statusBbTimeout => 'Timeout: 0xBB nicht empfangen';

  @override
  String statusHandshakeError(Object error) {
    return 'Handshake-Fehler: $error';
  }

  @override
  String statusTerminalStartError(Object error) {
    return 'Fehler beim Starten des Terminals: $error';
  }

  @override
  String get homeConnect => 'Verbinden';

  @override
  String get homeTerminal => 'Terminal';

  @override
  String get homeSpeedCurve => 'Fahrkurve';

  @override
  String get homeSoftwareUpdate => 'SW-Update';

  @override
  String get homeDownloadErrors => 'Fehler Liste';

  @override
  String get homeDownloadParameters => 'Parameter Speichern';

  @override
  String get homeUploadParameters => 'Parameter Laden';

  @override
  String get homeDocuments => 'Dokumente';

  @override
  String get homeAbout => 'Info';

  @override
  String get homeNotConnected => 'Nicht verbunden';

  @override
  String get homeConnectHint =>
      'Bitte verbinden Sie sich per Bluetooth mit dem Gerät.';

  @override
  String get bluetoothTitle => 'Bluetooth-Verbindung';

  @override
  String get bluetoothReady => 'Bereit';

  @override
  String get bluetoothScanning => 'Geräte werden gesucht...';

  @override
  String get bluetoothScanComplete => 'Suche abgeschlossen';

  @override
  String get bluetoothNoDevicesFound => 'Keine Geräte gefunden';

  @override
  String get bluetoothUnknownDevice => 'Unbekanntes Gerät';

  @override
  String get bluetoothScan => 'Suchen';

  @override
  String get bluetoothStop => 'Stoppen';

  @override
  String get bluetoothNotSupported => 'Dieses Gerät unterstützt BLE nicht';

  @override
  String get bluetoothScanError => 'Fehler bei der Suche';

  @override
  String get bluetoothStopError => 'Fehler beim Stoppen';

  @override
  String get bluetoothStopped => 'Suche gestoppt';

  @override
  String bluetoothConnecting(Object deviceName) {
    return '$deviceName wird verbunden...';
  }

  @override
  String get bluetoothMissingCharacteristics =>
      'Verbunden, aber erforderliche Merkmale wurden nicht gefunden';

  @override
  String get bluetoothConnectionError => 'Verbindungsfehler';

  @override
  String get bluetoothConnectionLost => 'Bluetooth-Verbindung verloren';

  @override
  String get bluetoothTurnOnRequired => 'Bluetooth muss eingeschaltet sein';

  @override
  String get bluetoothReconnecting => 'Verbindung wird wiederhergestellt...';

  @override
  String get parametersTitle => 'Parameterexport';

  @override
  String get parameterExportSubtitle => 'FB10-Parameterexport';

  @override
  String get downloadedPackets => 'Geladene Pakete';

  @override
  String get lastParameter => 'Letzter Parameter';

  @override
  String get connectionReady => 'Bereit';

  @override
  String get connectionWaiting => 'Warten';

  @override
  String get export => 'Export';

  @override
  String get exportReady => 'Bereit';

  @override
  String get exportPreparing => 'In Vorbereitung';

  @override
  String get txtExportReady => 'TXT-Export bereit';

  @override
  String get exportDescription =>
      'Die exportierte Parameterdatei kann gespeichert oder geteilt werden.';

  @override
  String get saveTxt => 'TXT speichern';

  @override
  String get preview => 'Vorschau';

  @override
  String get downloadProgress => 'Download-Fortschritt';

  @override
  String parameterProgressValue(int current, int total) {
    return '$current / $total';
  }

  @override
  String percentComplete(int percent) {
    return '$percent %';
  }

  @override
  String get noParameter => '—';
}
