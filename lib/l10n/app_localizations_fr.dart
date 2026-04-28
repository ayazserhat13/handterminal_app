// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Application terminal';

  @override
  String get screenTitle => 'Simulation écran TFT';

  @override
  String get menu => 'MENU';

  @override
  String get display => 'Affichage';

  @override
  String get graph => 'Graphique';

  @override
  String get connection => 'Connexion';

  @override
  String get settings => 'Paramètres';

  @override
  String get monitoring => 'Surveillance';

  @override
  String get errors => 'Erreurs';

  @override
  String get info => 'Info';

  @override
  String get quit => 'Quitter';

  @override
  String get down => 'Bas';

  @override
  String get up => 'Haut';

  @override
  String get enter => 'Entrer';

  @override
  String get lcdLineHello => 'Bonjour Monde! ';

  @override
  String get lcdLineFloor => 'Étage: 3 Haut  ';

  @override
  String get lcdLineReady => 'Système prêt...';

  @override
  String get lcdLineNoError => 'Aucune erreur  ';

  @override
  String get fb10Display => 'Écran FB10';

  @override
  String get errorLed => 'ERREUR';

  @override
  String get operateLed => 'MARCHE';

  @override
  String get monitor => 'Surveillance';

  @override
  String get ab => 'BAS';

  @override
  String get auf => 'HAUT';

  @override
  String get statusPreparingConnection => 'Préparation de la connexion...';

  @override
  String get statusHandshakeStarting => 'Démarrage du handshake...';

  @override
  String get statusWaitingForBb => 'Attente de 0xBB...';

  @override
  String get statusFirstBbReceived => 'Premier 0xBB reçu, envoi de 0xAA...';

  @override
  String get statusSecondBbReceived =>
      'Deuxième 0xBB reçu, démarrage du terminal...';

  @override
  String get statusTerminalReady => 'Terminal prêt';

  @override
  String get statusKeySendError => 'Erreur d\'envoi de touche';

  @override
  String get statusBbTimeout => 'Timeout : 0xBB non reçu';

  @override
  String statusHandshakeError(Object error) {
    return 'Erreur de handshake : $error';
  }

  @override
  String statusTerminalStartError(Object error) {
    return 'Erreur de démarrage du terminal : $error';
  }
}
