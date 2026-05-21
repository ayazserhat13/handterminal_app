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

  @override
  String get homeConnect => 'Connexion';

  @override
  String get homeTerminal => 'Terminal';

  @override
  String get homeSpeedCurve => 'Courbe de vitesse';

  @override
  String get homeSoftwareUpdate => 'Mise à jour logicielle';

  @override
  String get homeDownloadErrors => 'Télécharger les erreurs';

  @override
  String get homeDownloadParameters => 'Télécharger les paramètres';

  @override
  String get homeUploadParameters => 'Téléverser les paramètres';

  @override
  String get homeDocuments => 'Documents';

  @override
  String get homeAbout => 'À propos';

  @override
  String get homeNotConnected => 'Non connecté';

  @override
  String get homeConnectHint => 'Veuillez connecter l’appareil via Bluetooth.';

  @override
  String get bluetoothTitle => 'Connexion Bluetooth';

  @override
  String get bluetoothReady => 'Prêt';

  @override
  String get bluetoothScanning => 'Recherche d’appareils...';

  @override
  String get bluetoothScanComplete => 'Recherche terminée';

  @override
  String get bluetoothNoDevicesFound => 'Aucun appareil trouvé';

  @override
  String get bluetoothUnknownDevice => 'Appareil inconnu';

  @override
  String get bluetoothScan => 'Rechercher';

  @override
  String get bluetoothStop => 'Arrêter';

  @override
  String get bluetoothNotSupported =>
      'Cet appareil ne prend pas en charge le BLE';

  @override
  String get bluetoothScanError => 'Erreur de recherche';

  @override
  String get bluetoothStopError => 'Erreur lors de l’arrêt';

  @override
  String get bluetoothStopped => 'Recherche arrêtée';

  @override
  String bluetoothConnecting(Object deviceName) {
    return 'Connexion à $deviceName...';
  }

  @override
  String get bluetoothMissingCharacteristics =>
      'Connecté, mais les caractéristiques requises sont introuvables';

  @override
  String get bluetoothConnectionError => 'Erreur de connexion';

  @override
  String get bluetoothConnectionLost => 'Connexion Bluetooth perdue';

  @override
  String get bluetoothTurnOnRequired => 'Le Bluetooth doit être activé';

  @override
  String get bluetoothReconnecting => 'Reconnexion en cours...';

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
