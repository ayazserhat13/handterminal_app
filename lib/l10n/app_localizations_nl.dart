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
}
