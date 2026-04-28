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
}
