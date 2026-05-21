import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('nl'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Handterminal App'**
  String get appTitle;

  /// No description provided for @screenTitle.
  ///
  /// In en, this message translates to:
  /// **'TFT Display Simulation'**
  String get screenTitle;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'MENU'**
  String get menu;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @graph.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get graph;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @monitoring.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get monitoring;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @down.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get down;

  /// No description provided for @up.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get up;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// No description provided for @lcdLineHello.
  ///
  /// In en, this message translates to:
  /// **'Hello World!   '**
  String get lcdLineHello;

  /// No description provided for @lcdLineFloor.
  ///
  /// In en, this message translates to:
  /// **'Floor: 3 Up    '**
  String get lcdLineFloor;

  /// No description provided for @lcdLineReady.
  ///
  /// In en, this message translates to:
  /// **'System Ready...'**
  String get lcdLineReady;

  /// No description provided for @lcdLineNoError.
  ///
  /// In en, this message translates to:
  /// **'No Error       '**
  String get lcdLineNoError;

  /// No description provided for @fb10Display.
  ///
  /// In en, this message translates to:
  /// **'FB10 Display'**
  String get fb10Display;

  /// No description provided for @errorLed.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get errorLed;

  /// No description provided for @operateLed.
  ///
  /// In en, this message translates to:
  /// **'OPERATE'**
  String get operateLed;

  /// No description provided for @monitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get monitor;

  /// No description provided for @ab.
  ///
  /// In en, this message translates to:
  /// **'DOWN'**
  String get ab;

  /// No description provided for @auf.
  ///
  /// In en, this message translates to:
  /// **'UP'**
  String get auf;

  /// No description provided for @statusPreparingConnection.
  ///
  /// In en, this message translates to:
  /// **'Preparing connection...'**
  String get statusPreparingConnection;

  /// No description provided for @statusHandshakeStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting handshake...'**
  String get statusHandshakeStarting;

  /// No description provided for @statusWaitingForBb.
  ///
  /// In en, this message translates to:
  /// **'Waiting for 0xBB...'**
  String get statusWaitingForBb;

  /// No description provided for @statusFirstBbReceived.
  ///
  /// In en, this message translates to:
  /// **'First 0xBB received, sending 0xAA...'**
  String get statusFirstBbReceived;

  /// No description provided for @statusSecondBbReceived.
  ///
  /// In en, this message translates to:
  /// **'Second 0xBB received, starting terminal...'**
  String get statusSecondBbReceived;

  /// No description provided for @statusTerminalReady.
  ///
  /// In en, this message translates to:
  /// **'Terminal ready'**
  String get statusTerminalReady;

  /// No description provided for @statusKeySendError.
  ///
  /// In en, this message translates to:
  /// **'Key send error'**
  String get statusKeySendError;

  /// No description provided for @statusBbTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout: 0xBB not received'**
  String get statusBbTimeout;

  /// No description provided for @statusHandshakeError.
  ///
  /// In en, this message translates to:
  /// **'Handshake error: {error}'**
  String statusHandshakeError(Object error);

  /// No description provided for @statusTerminalStartError.
  ///
  /// In en, this message translates to:
  /// **'Terminal start error: {error}'**
  String statusTerminalStartError(Object error);

  /// No description provided for @homeConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get homeConnect;

  /// No description provided for @homeTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get homeTerminal;

  /// No description provided for @homeSpeedCurve.
  ///
  /// In en, this message translates to:
  /// **'Speed Curve'**
  String get homeSpeedCurve;

  /// No description provided for @homeSoftwareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Software Update'**
  String get homeSoftwareUpdate;

  /// No description provided for @homeDownloadErrors.
  ///
  /// In en, this message translates to:
  /// **'Download Errors'**
  String get homeDownloadErrors;

  /// No description provided for @homeDownloadParameters.
  ///
  /// In en, this message translates to:
  /// **'Download Parameters'**
  String get homeDownloadParameters;

  /// No description provided for @homeUploadParameters.
  ///
  /// In en, this message translates to:
  /// **'Upload Parameters'**
  String get homeUploadParameters;

  /// No description provided for @homeDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get homeDocuments;

  /// No description provided for @homeAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get homeAbout;

  /// No description provided for @homeNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get homeNotConnected;

  /// No description provided for @homeConnectHint.
  ///
  /// In en, this message translates to:
  /// **'Please connect to the device via Bluetooth.'**
  String get homeConnectHint;

  /// No description provided for @bluetoothTitle.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth Connection'**
  String get bluetoothTitle;

  /// No description provided for @bluetoothReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get bluetoothReady;

  /// No description provided for @bluetoothScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning for devices...'**
  String get bluetoothScanning;

  /// No description provided for @bluetoothScanComplete.
  ///
  /// In en, this message translates to:
  /// **'Scan complete'**
  String get bluetoothScanComplete;

  /// No description provided for @bluetoothNoDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get bluetoothNoDevicesFound;

  /// No description provided for @bluetoothUnknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get bluetoothUnknownDevice;

  /// No description provided for @bluetoothScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get bluetoothScan;

  /// No description provided for @bluetoothStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get bluetoothStop;

  /// No description provided for @bluetoothNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This device does not support BLE'**
  String get bluetoothNotSupported;

  /// No description provided for @bluetoothScanError.
  ///
  /// In en, this message translates to:
  /// **'Scan error'**
  String get bluetoothScanError;

  /// No description provided for @bluetoothStopError.
  ///
  /// In en, this message translates to:
  /// **'Stop error'**
  String get bluetoothStopError;

  /// No description provided for @bluetoothStopped.
  ///
  /// In en, this message translates to:
  /// **'Scan stopped'**
  String get bluetoothStopped;

  /// No description provided for @bluetoothConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {deviceName}...'**
  String bluetoothConnecting(Object deviceName);

  /// No description provided for @bluetoothMissingCharacteristics.
  ///
  /// In en, this message translates to:
  /// **'Connected, but required characteristics were not found'**
  String get bluetoothMissingCharacteristics;

  /// No description provided for @bluetoothConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get bluetoothConnectionError;

  /// No description provided for @bluetoothConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth connection lost'**
  String get bluetoothConnectionLost;

  /// No description provided for @bluetoothTurnOnRequired.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth must be turned on'**
  String get bluetoothTurnOnRequired;

  /// No description provided for @bluetoothReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get bluetoothReconnecting;

  /// No description provided for @parametersTitle.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get parametersTitle;

  /// No description provided for @parameterExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FB10 parameter export'**
  String get parameterExportSubtitle;

  /// No description provided for @downloadedPackets.
  ///
  /// In en, this message translates to:
  /// **'Downloaded packets'**
  String get downloadedPackets;

  /// No description provided for @lastParameter.
  ///
  /// In en, this message translates to:
  /// **'Last parameter'**
  String get lastParameter;

  /// No description provided for @connectionReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get connectionReady;

  /// No description provided for @connectionWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get connectionWaiting;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get exportReady;

  /// No description provided for @exportPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get exportPreparing;

  /// No description provided for @txtExportReady.
  ///
  /// In en, this message translates to:
  /// **'TXT Export Ready'**
  String get txtExportReady;

  /// No description provided for @exportDescription.
  ///
  /// In en, this message translates to:
  /// **'Exported parameter file can be saved or shared.'**
  String get exportDescription;

  /// No description provided for @saveTxt.
  ///
  /// In en, this message translates to:
  /// **'Save TXT'**
  String get saveTxt;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Download progress'**
  String get downloadProgress;

  /// No description provided for @parameterProgressValue.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String parameterProgressValue(int current, int total);

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String percentComplete(int percent);

  /// No description provided for @noParameter.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get noParameter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'nl', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'nl':
      return AppLocalizationsNl();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
