import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handterminal_app/core/fb10/fb10_commands.dart';
import 'package:handterminal_app/core/fb10/fb10_write_queue.dart';
import 'package:handterminal_app/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ParameterDownloadScreen extends StatefulWidget {
  final BluetoothCharacteristic writeCharacteristic;
  final BluetoothCharacteristic notifyCharacteristic;

  const ParameterDownloadScreen({
    super.key,
    required this.writeCharacteristic,
    required this.notifyCharacteristic,
  });

  @override
  State<ParameterDownloadScreen> createState() =>
      _ParameterDownloadScreenState();
}

class _ParameterDownloadScreenState extends State<ParameterDownloadScreen> {
  static const int _expectedLastIndex = 138;
  static const bool _useEepromOnlyDownload = true;
  static const Duration _keepaliveInterval = Duration(milliseconds: 250);
  static const Color _accentColor = Color(0xFF0A4C93);
  static const Color _readyColor = Color(0xFF0F7B4B);
  static const Color _pendingColor = Color(0xFF64748B);
  static const Color _screenBackground = Color(0xFFF4F7FA);
  static const Color _cardBorderColor = Color(0xFFE1E7EF);
  static const int _geschwV0Index = 3;
  static const int _geschwV1Index = 4;
  static const int _geschwV2Index = 5;
  static const int _geschwV3Index = 6;
  static const int _beschlIndex = 7;
  static const int _ruckBeshIndex = 8;
  static const int _verzoeIndex = 9;
  static const int _ruckVerzIndex = 10;
  static const int _messfahrtIndex = 11;
  static const int _startVerIndex = 12;
  static const int _bremswegV0Index = 13;
  static const int _drkEinfIndex = 14;
  static const int _startBoostIndex = 15;
  static const int _start1PIndex = 16;
  static const int _start1IIndex = 17;
  static const int _start1TIndex = 18;
  static const int _passwortIndex = 38;
  static const int _losreisDrehzIndex = 21;
  static const int _losreisTIndex = 22;
  static const int _geberSystemIndex = 23;
  static const int _geberAbrlIndex = 24;
  static const int _inkStrichIndex = 25;
  static const int _motDrehzIndex = 26;
  static const int _motFreqIndex = 27;
  static const int _motStromIndex = 28;
  static const int _getUeberIndex = 30;
  static const int _getTreibIndex = 31;
  static const int _getAufhIndex = 32;
  static const int _syncPolIndex = 48;
  static const int _feldEinIndex = 53;
  static const int _feldAbsIndex = 54;
  static const int _feldPt1Index = 55;
  static const int _motMagIndex = 59;
  static const int _stromBgrIndex = 62;
  static const int _wartHseIndex = 69;
  static const int _warteHsaIndex = 70;
  static const int _vzTaFahrtIndex = 76;
  static const int _bremsVxIndex = 77;
  static const int _motKaltleiterIndex = 79;
  static const int _hsUeberwIndex = 89;
  static const int _motorTypIndex = 94;
  static const int _dcAnteilIndex = 95;
  static const int _igbtTaktIndex = 98;
  static const int _udUqmaxIndex = 99;
  static const int _peRelaisIndex = 100;
  static const int _startArtIndex = 101;
  static const int _drRegFaktorStartIndex = 109;
  static const int _uMotorIndex = 110;
  static const int _spitzfuncIndex = 87;
  static const int _readableLineLabelWidth = 29;
  static const _readableCategoryOrder = <_ReadableParameterCategory>[
    _ReadableParameterCategory.speed,
    _ReadableParameterCategory.travelCurve,
    _ReadableParameterCategory.startStop,
    _ReadableParameterCategory.drive,
    _ReadableParameterCategory.interfaces,
    _ReadableParameterCategory.operatingParameters,
    _ReadableParameterCategory.controllerParameters,
    _ReadableParameterCategory.tuvMenu,
    _ReadableParameterCategory.hardware,
    _ReadableParameterCategory.internalTimings,
    _ReadableParameterCategory.miscellaneous,
  ];
  static const _readableCategoryTitles =
      <_ReadableParameterCategory, Map<String, String>>{
        _ReadableParameterCategory.speed: <String, String>{
          'de': 'Geschwindigkeit',
          'en': 'Speed',
          'fr': 'Vitesse',
          'nl': 'Snelheid',
        },
        _ReadableParameterCategory.travelCurve: <String, String>{
          'de': 'Fahrkurve',
          'en': 'Travel curve',
          'fr': 'Courbe de marche',
          'nl': 'Rijcurve',
        },
        _ReadableParameterCategory.startStop: <String, String>{
          'de': 'Start-Stop',
          'en': 'Start-Stop',
          'fr': 'Start-Stop',
          'nl': 'Start-Stop',
        },
        _ReadableParameterCategory.drive: <String, String>{
          'de': 'Antrieb',
          'en': 'Drive',
          'fr': 'Entraînement',
          'nl': 'Aandrijving',
        },
        _ReadableParameterCategory.interfaces: <String, String>{
          'de': 'Schnittstellen',
          'en': 'Interfaces',
          'fr': 'Interfaces',
          'nl': 'Interfaces',
        },
        _ReadableParameterCategory.operatingParameters: <String, String>{
          'de': 'Bedienparameter',
          'en': 'Operating parameters',
          'fr': 'Paramètres utilisateur',
          'nl': 'Bedieningsparameters',
        },
        _ReadableParameterCategory.controllerParameters: <String, String>{
          'de': 'Reglerparameter',
          'en': 'Controller parameters',
          'fr': 'Paramètres régulateur',
          'nl': 'Regelaarparameters',
        },
        _ReadableParameterCategory.tuvMenu: <String, String>{
          'de': 'TÜV Menü',
          'en': 'TÜV menu',
          'fr': 'TÜV menu',
          'nl': 'TÜV menu',
        },
        _ReadableParameterCategory.hardware: <String, String>{
          'de': 'Hardware',
          'en': 'Hardware',
          'fr': 'Hardware',
          'nl': 'Hardware',
        },
        _ReadableParameterCategory.internalTimings: <String, String>{
          'de': 'Interne Zeiten',
          'en': 'Internal timings',
          'fr': 'Temps internes',
          'nl': 'Interne tijden',
        },
        _ReadableParameterCategory.miscellaneous: <String, String>{
          'de': 'Sonstiges',
          'en': 'Miscellaneous',
          'fr': 'Divers',
          'nl': 'Overige',
        },
      };
  static const _speedParameterDescriptors = <_ParameterDescriptor>[
    _ParameterDescriptor(
      index: 1,
      parameter: 'GeschwVn',
      label: 'Vn',
      category: _ReadableParameterCategory.speed,
    ),
    _ParameterDescriptor(
      index: 2,
      parameter: 'GeschwVi',
      label: 'Vi',
      category: _ReadableParameterCategory.speed,
    ),
    _ParameterDescriptor(
      index: 3,
      parameter: 'GeschwV0',
      label: 'V0',
      category: _ReadableParameterCategory.speed,
    ),
    _ParameterDescriptor(
      index: 4,
      parameter: 'GeschwV1',
      label: 'V1',
      category: _ReadableParameterCategory.speed,
    ),
    _ParameterDescriptor(
      index: 5,
      parameter: 'GeschwV2',
      label: 'V2',
      category: _ReadableParameterCategory.speed,
    ),
    _ParameterDescriptor(
      index: 6,
      parameter: 'GeschwV3',
      label: 'V3',
      category: _ReadableParameterCategory.speed,
    ),
  ];
  static const _brakeDistanceSpeedIndexes = <int>[
    _geschwV1Index,
    _geschwV2Index,
    _geschwV3Index,
  ];
  static const _readableMotorTypeLabels = <String, String>{
    '0.0': 'Asynchronous',
    '0.1': 'Asynchronous open loop',
    '0.2': 'Synchronous',
    '1.0': 'WSG-TB',
    '1.1': 'WSG-TR',
    '1.2': 'WSG-TS',
    '1.3': 'WSG-RF',
    '1.4': 'WSG-SF',
    '1.5': 'WSG-MF',
    '1.6': 'WSG-LF',
    '1.7': 'WSG-08',
    '1.8': 'WSG-21',
    '1.9': 'WSG-25',
    '1.10': 'WSG-29',
    '1.11': 'WGG-29',
    '1.12': 'WSG-52',
    '2.0': 'TW45C',
    '2.1': 'TW63B',
    '2.2': 'TW130',
    '2.3': 'TW160',
    '2.4': 'W332C',
    '2.5': 'DAF270',
    '2.6': 'SC400',
    '2.7': 'SC500',
    '2.8': 'PMC125/145',
    '3.0': 'EPM 100',
    '3.1': 'EPM 300',
    '3.2': 'EPM 500',
  };
  static const _igbtSwitchingFrequencyLabels = <int, String>{
    0: '16 kHz',
    1: '8 kHz',
    2: 'Auto',
    3: '10 kHz',
    4: '12 kHz',
  };
  static const _inspectionSwitchingFrequencyLabels = <int, String>{
    0: '8 kHz',
    1: '4 kHz',
    2: '2 kHz',
    3: '16 kHz',
    4: '10 kHz',
    5: '12 kHz',
  };
  static const List<String> _rtcDspRamFieldNames = <String>[
    'Start',
    'GeschwVn',
    'GeschwVi',
    'GeschwV0',
    'GeschwV1',
    'GeschwV2',
    'GeschwV3',
    'Beschl',
    'RuckBesh',
    'Verzoe',
    'RuckVerz',
    'Messfahrt',
    'StartVer',
    'BremswegV0',
    'DrkEinf',
    'StartBoost',
    'Start1P',
    'Start1I',
    'Start1T',
    'BoostK',
    'SchlupfK',
    'LosreisDrehz',
    'LosreisT',
    'GeberSystem',
    'GeberABRL',
    'InkStrich',
    'MotDrehz',
    'MotFreq',
    'MotStrom',
    'MotCosphi',
    'GetUeber',
    'GetTreib',
    'GetAufh',
    'RelaisV3',
    'RelaisVx',
    'RelaisPr',
    'RelaisPrVx',
    'progEingang',
    'Passwort',
    'Passwort_0',
    'Sprache',
    'DaempfStr',
    'DaempfBes',
    'DaempfFar',
    'DaempfVer',
    'DaempfReg',
    'DrRegP',
    'DrRegI',
    'SyncPol',
    'StRegIdP',
    'StRegIdI',
    'StRegIqP',
    'StRegIqI',
    'FeldEin',
    'FeldAbs',
    'FeldPT1',
    'VRegPDyn',
    'VRegPDif',
    'StrRegIqPT1',
    'MotMag',
    'UmrTyp',
    'MaxStrom',
    'StromBgr',
    'Netzspg',
    'StrSens',
    'MessWid',
    'BrmMin',
    'BrmMax',
    'IGBTTot',
    'WartHSE',
    'WartHSA',
    'NachBrm',
    'VzTaStart',
    'Schleich',
    'VzVorlad',
    'Menu0',
    'VzTaFahrt',
    'BremsVx',
    'ChopFreq',
    'MotKaltleiter',
    'SSITakt',
    'SSIBits',
    'Hardware',
    'VzInspektion',
    'Eva_Bat_Spg',
    'Eva_UeberSteuer',
    'Bussys',
    'Spitzfunc',
    'DCPKorrektur',
    'HSUeberw',
    'Kunde',
    'MotorStromlos',
    'Fehler01_16',
    'Fehler17_32',
    'BremsenUw',
    'DCAnteil',
    'Para_Frei05',
    'progEingangV2',
    'IGBTTakt',
    'UdUqmax',
    'PERelais',
    'StartArt',
    'StrRegI',
    'StrRegD',
    'StrRegC',
    'DrRegD',
    'DrRegC',
    'Start1D',
    'DaempfEinf',
    'DrRegFaktorStart',
    'UMotor',
    'SyncSpalt',
    'Para_Frei21',
    'BremswegV1de',
    'BremswegV2de',
    'BremswegV3de',
    'Para_Frei25',
    'BremswegVi_H',
    'BremswegVi_L',
    'BremswegV1_H',
    'BremswegV1_L',
    'BremswegV2_H',
    'BremswegV2_L',
    'BremswegV3_H',
    'BremswegV3_L',
    'Leer',
    'RTC',
    'LufterON',
    'LufterOFF',
    'Kurzschluss',
    'progEingangV3',
    'SimDSPTyp',
    'DCPGrenzgeschw',
    'DrRegFaktor',
    'ABTeiler',
    'VzSteuinms',
    'Host_Version',
    'Checksum',
    'End',
  ];

  final Map<int, int> _parameters = <int, int>{};
  final List<int> _rxBuffer = <int>[];
  final List<int?> _eepromWords = List<int?>.filled(256, null);
  final List<int> _eepromRxBuffer = <int>[];

  late final Fb10WriteQueue _writeQueue;
  StreamSubscription<List<int>>? _notifySub;
  Future<void> _notifyChain = Future<void>.value();
  Timer? _keepaliveTimer;
  Timer? _handshakeTimer;

  int _packetCount = 0;
  int? _lastIndex;
  String? _txtExport;
  bool _eepromReadStarted = false;
  bool _eepromReadComplete = false;
  int _eepromPacketCount = 0;
  int? _lastEepromAddress;
  int? _lastEepromValue;
  int _handshakeTryCount = 0;
  bool _waitingForHandshakeBb = false;
  bool _downloadComplete = false;
  bool _driverReady = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _writeQueue = Fb10WriteQueue(writer: _writeBytesDirect);
    _listenNotify();
    unawaited(_startParameterDownload());
  }

  @override
  void dispose() {
    debugPrint('PARAM SCREEN DISPOSE');
    _disposed = true;
    _keepaliveTimer?.cancel();
    _handshakeTimer?.cancel();
    _eepromRxBuffer.clear();
    _notifySub?.cancel();
    _writeQueue.close();
    super.dispose();
  }

  void _listenNotify() {
    _notifySub = widget.notifyCharacteristic.onValueReceived.listen((value) {
      if (value.isEmpty) return;

      final chunk = List<int>.from(value);
      _notifyChain = _notifyChain
          .then<void>((_) => _handleNotifyChunk(chunk))
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint('PARAM: notify error $error');
          });
    });
  }

  Future<void> _startParameterDownload() async {
    _keepaliveTimer?.cancel();
    _rxBuffer.clear();
    _eepromRxBuffer.clear();
    _eepromWords.fillRange(0, _eepromWords.length, null);
    _parameters.clear();

    if (mounted) {
      setState(() {
        _packetCount = 0;
        _lastIndex = null;
        _txtExport = null;
        _eepromReadStarted = false;
        _eepromReadComplete = false;
        _eepromPacketCount = 0;
        _lastEepromAddress = null;
        _lastEepromValue = null;
        _downloadComplete = false;
        _driverReady = false;
      });
    }

    if (_useEepromOnlyDownload) {
      debugPrint('PARAM EEPROM-only download mode');
      await _startEepromRead();
      return;
    }

    await _writeBytes(const [Fb10Commands.parameterDownload]);
    debugPrint('PARAM START 0x10');
  }

  Future<void> _handleNotifyChunk(List<int> value) async {
    if (_disposed) return;

    if (_waitingForHandshakeBb) {
      if (value.contains(Fb10Commands.handshakeResponse)) {
        debugPrint('PARAM handshake RX 0xBB');
        await _completeHandshakeRestart();
      }
      return;
    }

    if (_eepromReadStarted && !_eepromReadComplete) {
      await _handleEepromNotify(value);
      return;
    }

    if (_downloadComplete) {
      await _handleKeepaliveNotify(value);
      return;
    }

    _rxBuffer.addAll(value);

    while (_rxBuffer.length >= 4) {
      final index = _rxBuffer[0];
      final low = _rxBuffer[1];
      final high = _rxBuffer[2];
      final checksum = _rxBuffer[3];
      final expectedChecksum = (index + low + high) & 0xFF;

      if (checksum != expectedChecksum) {
        debugPrint('PARAM resync drop ${_formatByte(index)}');
        _rxBuffer.removeAt(0);
        continue;
      }

      _rxBuffer.removeRange(0, 4);

      await _handlePacket(index, low, high, checksum);
      if (_downloadComplete) return;
    }
  }

  Future<void> _handleKeepaliveNotify(List<int> value) async {
    if (!value.contains(Fb10Commands.handshakeResponse)) return;

    debugPrint('PARAM RX 0xBB ready');

    if (mounted) {
      setState(() {
        _driverReady = true;
      });
    } else {
      _driverReady = true;
    }

    if (!_eepromReadStarted && !_eepromReadComplete) {
      await _startEepromRead();
    }
  }

  Future<void> _startEepromRead() async {
    if (_disposed || _eepromReadStarted || _eepromReadComplete) return;

    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _writeQueue.clearPending();
    _eepromRxBuffer.clear();
    _eepromWords.fillRange(0, _eepromWords.length, null);

    if (mounted) {
      setState(() {
        _driverReady = false;
        _eepromReadStarted = true;
        _eepromReadComplete = false;
        _eepromPacketCount = 0;
        _lastEepromAddress = null;
        _lastEepromValue = null;
      });
    } else {
      _driverReady = false;
      _eepromReadStarted = true;
      _eepromReadComplete = false;
      _eepromPacketCount = 0;
      _lastEepromAddress = null;
      _lastEepromValue = null;
    }

    debugPrint('PARAM EEPROM START 0x71');
    await _writeBytes(const [Fb10Commands.eepromRead]);
  }

  Future<void> _handleEepromNotify(List<int> value) async {
    _eepromRxBuffer.addAll(value);

    while (_eepromRxBuffer.length >= 4) {
      final address = _eepromRxBuffer[0];
      final low = _eepromRxBuffer[1];
      final high = _eepromRxBuffer[2];
      final checksum = _eepromRxBuffer[3];
      final expectedChecksum = (address + low + high) & 0xFF;

      if (checksum != expectedChecksum) {
        debugPrint('PARAM EEPROM resync drop ${_formatByte(address)}');
        _eepromRxBuffer.removeAt(0);
        continue;
      }

      _eepromRxBuffer.removeRange(0, 4);

      final eepromValue = low | (high << 8);
      _eepromWords[address] = eepromValue;

      if (mounted) {
        setState(() {
          _eepromPacketCount++;
          _lastEepromAddress = address;
          _lastEepromValue = eepromValue;
        });
      } else {
        _eepromPacketCount++;
        _lastEepromAddress = address;
        _lastEepromValue = eepromValue;
      }

      debugPrint('PARAM EEPROM addr=$address value=$eepromValue checksum ok');
      debugPrint('PARAM EEPROM ACK ${_formatByte(checksum)}');
      await _writeBytes([checksum]);

      if (address == 0xFF) {
        _completeEepromRead();
        break;
      }
    }
  }

  void _completeEepromRead() {
    if (_eepromReadComplete) return;

    _eepromRxBuffer.clear();
    final wordsRead = _eepromWords.whereType<int>().length;

    if (mounted) {
      setState(() {
        _eepromReadComplete = true;
        _eepromReadStarted = false;
      });
    } else {
      _eepromReadComplete = true;
      _eepromReadStarted = false;
    }

    debugPrint('PARAM EEPROM complete words=$wordsRead');
    final txtExport = _rebuildTxtExport();

    if (mounted) {
      setState(() {
        _txtExport = txtExport;
        _downloadComplete = true;
      });
    } else {
      _txtExport = txtExport;
      _downloadComplete = true;
    }

    _logEepromParameterVerification();
    _logFullEepromParameterVerification();
    unawaited(_restartHandshakeAfterEeprom());
  }

  void _logEepromParameterVerification() {
    if (_useEepromOnlyDownload || _parameters.isEmpty) return;

    const verificationIndexes = <int>[30, 31, 32, 94, 98, 100, 110];
    var matchCount = 0;

    for (final index in verificationIndexes) {
      final parameterValue = _parameters[index];
      final eepromValue = _eepromWords[index];
      final matches =
          parameterValue != null &&
          eepromValue != null &&
          parameterValue == eepromValue;
      if (matches) {
        matchCount++;
      }

      debugPrint(
        'PARAM EEPROM VERIFY idx=$index '
        'param=$parameterValue eeprom=$eepromValue match=$matches',
      );
    }

    debugPrint(
      'PARAM EEPROM VERIFY summary matches=$matchCount/'
      '${verificationIndexes.length}',
    );
  }

  void _logFullEepromParameterVerification() {
    if (_useEepromOnlyDownload || _parameters.isEmpty) {
      debugPrint(
        'PARAM EEPROM FULL VERIFY skipped; parameter download disabled',
      );
      return;
    }

    const maxIssueLogs = 20;
    final issueLogs = <String>[];
    var matchCount = 0;
    var mismatchCount = 0;
    var missingCount = 0;

    for (var index = 0; index <= _expectedLastIndex; index++) {
      final parameterValue = _parameters[index];
      final eepromValue = _eepromWords[index];

      if (parameterValue == null || eepromValue == null) {
        missingCount++;
        if (issueLogs.length < maxIssueLogs) {
          issueLogs.add(
            'PARAM EEPROM FULL VERIFY issue idx=$index '
            'param=$parameterValue eeprom=$eepromValue reason=missing',
          );
        }
        continue;
      }

      if (parameterValue == eepromValue) {
        matchCount++;
      } else {
        mismatchCount++;
        if (issueLogs.length < maxIssueLogs) {
          issueLogs.add(
            'PARAM EEPROM FULL VERIFY issue idx=$index '
            'param=$parameterValue eeprom=$eepromValue reason=mismatch',
          );
        }
      }
    }

    debugPrint(
      'PARAM EEPROM FULL VERIFY matches=$matchCount/'
      '${_expectedLastIndex + 1} mismatches=$mismatchCount '
      'missing=$missingCount',
    );

    for (final issueLog in issueLogs) {
      debugPrint(issueLog);
    }
  }

  Future<void> _handlePacket(int index, int low, int high, int checksum) async {
    final expectedChecksum = (index + low + high) & 0xFF;

    if (checksum != expectedChecksum) {
      debugPrint('PARAM: checksum error idx=$index');
      return;
    }

    final value = low | (high << 8);
    _parameters[index] = value;

    if (mounted) {
      setState(() {
        _packetCount++;
        _lastIndex = index;
      });
    }

    debugPrint('PARAM RX idx=$index value=$value checksum=$checksum');
    await _writeBytes([checksum]);
    debugPrint('PARAM ACK ${_formatByte(checksum)}');

    if (index >= _expectedLastIndex) {
      _completeDownload();
    }
  }

  void _completeDownload() {
    if (_downloadComplete) return;

    _rxBuffer.clear();
    debugPrint('PARAM download complete');
    final txtExport = _rebuildTxtExport();

    if (mounted) {
      setState(() {
        _txtExport = txtExport;
        _downloadComplete = true;
      });
    } else {
      _txtExport = txtExport;
      _downloadComplete = true;
    }

    _startKeepalive();
  }

  String _rebuildTxtExport() {
    final txtExport = _buildReadableTxtExportV1();
    debugPrint('PARAM TXT export ready (${txtExport.length} chars)');
    return txtExport;
  }

  void _startKeepalive({bool sendImmediately = true}) {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = Timer.periodic(_keepaliveInterval, (_) {
      unawaited(_sendKeepalive());
    });
    if (sendImmediately) {
      unawaited(_sendKeepalive());
    }
  }

  Future<void> _sendKeepalive() async {
    if (_disposed) return;

    debugPrint('PARAM KEEPALIVE 0xAA');
    await _writeBytes(const [Fb10Commands.handshakeAck]);
  }

  Future<void> _writeBytes(List<int> bytes) {
    if (_disposed) return Future<void>.value();
    return _writeQueue.enqueue(bytes);
  }

  Future<void> _writeBytesDirect(List<int> bytes) {
    return widget.writeCharacteristic.write(
      bytes,
      withoutResponse:
          widget.writeCharacteristic.properties.writeWithoutResponse,
    );
  }

  String _formatByte(int byte) {
    return '0x${byte.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  int? _parameterValue(int index) {
    if (_eepromReadComplete && index >= 0 && index < _eepromWords.length) {
      return _eepromWords[index];
    }
    return _parameters[index];
  }

  bool get _canSaveTxt {
    return _downloadComplete &&
        _driverReady &&
        !_waitingForHandshakeBb &&
        !_eepromReadStarted &&
        (!_useEepromOnlyDownload || _eepromReadComplete) &&
        _txtExport != null;
  }

  Future<void> _shareTxtExport() async {
    if (!_canSaveTxt) return;

    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _writeQueue.clearPending();
    debugPrint('PARAM keepalive paused for share');

    try {
      final txtExport = _buildReadableTxtExportV1();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${_buildTxtExportFileName()}');

      await file.writeAsString(txtExport);
      debugPrint('PARAM TXT write ${file.path}');

      final box = context.findRenderObject() as RenderBox?;

      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        subject: _buildTxtExportFileName(),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );

      debugPrint('PARAM TXT share opened');
    } catch (error) {
      debugPrint('PARAM TXT EXPORT ERROR: $error');
    } finally {
      debugPrint('PARAM share finished; restarting handshake');
      if (_downloadComplete && mounted) {
        unawaited(_restartHandshakeAfterShare());
      }
    }
  }

  Future<void> _restartHandshakeAfterShare() {
    return _restartHandshake(reason: 'after share');
  }

  Future<void> _restartHandshakeAfterEeprom() {
    return _restartHandshake(reason: 'after EEPROM');
  }

  Future<void> _restartHandshake({required String reason}) async {
    if (_disposed) return;

    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _writeQueue.clearPending();
    _waitingForHandshakeBb = true;
    _handshakeTryCount = 0;
    debugPrint('PARAM handshake restart $reason');

    if (mounted) {
      setState(() {
        _driverReady = false;
      });
    } else {
      _driverReady = false;
    }

    unawaited(_sendHandshakeRestartByte());
    _handshakeTimer = Timer.periodic(
      Fb10Timings.handshakeRetryInterval,
      (_) => unawaited(_sendHandshakeRestartByte()),
    );
  }

  Future<void> _sendHandshakeRestartByte() async {
    if (_disposed || !_waitingForHandshakeBb) return;

    if (_handshakeTryCount >= 100) {
      _stopHandshakeRestartAttempts();
      return;
    }

    final byteToSend = _handshakeTryCount.isEven
        ? Fb10Commands.handshakeWake
        : Fb10Commands.handshakeRequest;
    _handshakeTryCount++;
    debugPrint(
      'PARAM handshake try $_handshakeTryCount byte ${_formatByte(byteToSend)}',
    );
    await _writeBytes(<int>[byteToSend]);

    if (_handshakeTryCount >= 100 && _waitingForHandshakeBb) {
      _stopHandshakeRestartAttempts();
    }
  }

  void _stopHandshakeRestartAttempts() {
    if (_handshakeTimer == null) return;

    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    debugPrint(
      'PARAM handshake restart stopped after $_handshakeTryCount tries',
    );
  }

  Future<void> _completeHandshakeRestart() async {
    if (!_waitingForHandshakeBb) return;

    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _waitingForHandshakeBb = false;
    _writeQueue.clearPending();
    debugPrint('PARAM handshake complete; sending 0xAA');

    await _writeBytes(const [Fb10Commands.handshakeAck]);
    if (_disposed) return;

    if (mounted) {
      setState(() {
        _driverReady = true;
      });
    } else {
      _driverReady = true;
    }

    _startKeepalive(sendImmediately: false);
  }

  String _buildRawTxtExport() {
    final now = DateTime.now();
    final buffer = StringBuffer()
      ..writeln('FB10 Parameter Export')
      ..writeln('Date: ${_formatExportDateTime(now)}')
      ..writeln('Source: FB10')
      ..writeln('Format: Raw RTC_DSPRAM')
      ..writeln()
      ..writeln('Index;Parameter;Decimal;Hex');

    for (var index = 0; index <= _expectedLastIndex; index++) {
      final indexText = index.toString().padLeft(3, '0');
      final name = _parameterNameForIndex(index);
      final value = _parameters[index];

      if (value == null) {
        buffer.writeln('$indexText;$name;;');
      } else {
        buffer.writeln('$indexText;$name;$value;${_formatWord(value)}');
      }
    }

    return buffer.toString();
  }

  // Readable export is intentionally not wired to Save TXT yet; Save TXT remains raw.
  // ignore: unused_element
  String _buildReadableTxtExportV1() {
    final now = DateTime.now();
    final buffer = StringBuffer()
      ..writeln('FB10 Parameter Export')
      ..writeln('Date: ${_formatExportDateTime(now)}')
      ..writeln('Source: FB10')
      ..writeln('Format: Readable RTC_DSPRAM v1')
      ..writeln();

    for (var i = 0; i < _readableCategoryOrder.length; i++) {
      final category = _readableCategoryOrder[i];
      //buffer.writeln('[${_readableCategoryTitle(category)}]');
      buffer.writeln(_readableCategoryTitle(category).toUpperCase());

      if (category == _ReadableParameterCategory.speed) {
        buffer.writeln();
        for (final descriptor in _speedParameterDescriptors) {
          buffer.writeln(_buildReadableSpeedLine(descriptor));
        }
      }

      if (category == _ReadableParameterCategory.travelCurve) {
        buffer.writeln();
        for (final line in _buildReadableTravelCurveLines()) {
          buffer.writeln(line);
        }
      }

      if (category == _ReadableParameterCategory.startStop) {
        buffer.writeln();
        for (final line in _buildReadableStartStopLines()) {
          buffer.writeln(line);
        }
      }

      if (category == _ReadableParameterCategory.drive) {
        buffer.writeln();
        for (final line in _buildReadableDriveLines()) {
          buffer.writeln(line);
        }
      }

      if (i < _readableCategoryOrder.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _exportLanguageCode() {
    final localeCode =
        Localizations.maybeLocaleOf(context)?.languageCode ??
        Platform.localeName.split(RegExp('[-_]')).first;

    switch (localeCode.toLowerCase()) {
      case 'de':
      case 'en':
      case 'fr':
      case 'nl':
        return localeCode.toLowerCase();
      default:
        return 'en';
    }
  }

  String _readableCategoryTitle(_ReadableParameterCategory category) {
    final titles = _readableCategoryTitles[category];
    if (titles == null) return category.name;

    return titles[_exportLanguageCode()] ?? titles['en'] ?? category.name;
  }

  String _buildReadableSpeedLine(_ParameterDescriptor descriptor) {
    final upm = _parameterValue(descriptor.index);
    final upmText = upm == null ? ''.padLeft(6) : _formatUpm(upm);
    final mps = upm == null ? null : _upmToMetersPerSecond(upm);
    final mpsText = mps == null ? ''.padLeft(6) : _formatMetersPerSecond(mps);
    final label = descriptor.label.isEmpty
        ? descriptor.parameter
        : descriptor.label;
    final brakeDistanceSuffix = _buildReadableBrakeDistanceSuffix(
      descriptor.index,
    );

    return '${label.padRight(2)} : $upmText UPM $mpsText m/s$brakeDistanceSuffix';
  }

  String _buildReadableBrakeDistanceSuffix(int speedIndex) {
    if (!_brakeDistanceSpeedIndexes.contains(speedIndex)) return '';

    final label = _readableBrakeDistanceSuffixLabel();
    final distance = _calculateBrakeDistanceToV0Mm(speedIndex);
    final distanceText = distance == null ? '-' : '$distance mm';

    return '  $label: $distanceText';
  }

  List<String> _buildReadableTravelCurveLines() {
    final labels = _readableTravelCurveLabels();
    final rows = <({String label, String value})>[
      (
        label: labels.acceleration,
        value: _formatReadableHundredths(_parameterValue(_beschlIndex), 'm/s²'),
      ),
      (
        label: labels.accelerationJerk,
        value: _formatReadableHundredths(
          _parameterValue(_ruckBeshIndex),
          'm/s³',
        ),
      ),
      (
        label: labels.deceleration,
        value: _formatReadableHundredths(_parameterValue(_verzoeIndex), 'm/s²'),
      ),
      (
        label: labels.decelerationJerk,
        value: _formatReadableHundredths(
          _parameterValue(_ruckVerzIndex),
          'm/s³',
        ),
      ),
      (label: labels.v1Optimization, value: _formatReadableMessfahrtState(0)),
      (label: labels.v2Optimization, value: _formatReadableMessfahrtState(2)),
      (label: labels.v3Optimization, value: _formatReadableMessfahrtState(4)),
      (
        label: labels.peakCurve,
        value: _formatReadableSpitzfunc(_parameterValue(_spitzfuncIndex)),
      ),
      (
        label: labels.maxBrakingRamp,
        value: _formatReadableHundredths(_parameterValue(_bremsVxIndex), 'm/s'),
      ),
    ];
    final labelWidth = rows.fold<int>(
      _readableLineLabelWidth,
      (width, row) => row.label.length > width ? row.label.length : width,
    );

    return <String>[
      for (final row in rows)
        '${row.label.padRight(labelWidth)} : ${row.value}',
    ];
  }

  List<String> _buildReadableStartStopLines() {
    final labels = _readableStartStopLabels();
    final rows = <({String label, String value})>[
      (
        label: labels.startDelay,
        value: _formatReadableMilliseconds(_parameterValue(_startVerIndex)),
      ),
      (
        label: labels.brakingDistanceV0,
        value: _formatReadableTenthsUnit(
          _parameterValue(_bremswegV0Index),
          'mm',
        ),
      ),
      (
        label: labels.directLanding,
        value: _formatReadableDirectLanding(_parameterValue(_drkEinfIndex)),
      ),
      (
        label: labels.controllerBoostDcComponent,
        value: _formatReadablePercent(_parameterValue(_dcAnteilIndex)),
      ),
      (
        label: labels.controllerBoostPiValues,
        value: _formatReadablePercent(_parameterValue(_startBoostIndex)),
      ),
      (
        label: labels.positionControl,
        value: _formatReadableLageregelung(_parameterValue(_start1TIndex)),
      ),
      (
        label: labels.startControllerPComponent,
        value: _formatReadableRawInteger(_parameterValue(_start1PIndex)),
      ),
      (
        label: labels.startControllerIComponent,
        value: _formatReadableRawInteger(_parameterValue(_start1IIndex)),
      ),
      (
        label: labels.startControllerDComponent,
        value: _formatReadableRawInteger(_parameterValue(_startArtIndex)),
      ),
      (
        label: labels.startControllerFactor,
        value: _formatReadableMilliseconds(
          _parameterValue(_drRegFaktorStartIndex),
        ),
      ),
      (
        label: labels.breakawaySpeed,
        value: _formatReadableTenthsUnit(
          _parameterValue(_losreisDrehzIndex),
          'UPM',
        ),
      ),
      (
        label: labels.breakawayDuration,
        value: _formatReadableMilliseconds(_parameterValue(_losreisTIndex)),
      ),
      (
        label: labels.hsWaitingTime,
        value: _formatReadableAutoOrMs(_parameterValue(_wartHseIndex)),
      ),
      (
        label: labels.nbsRunOnTime,
        value: _formatReadableMilliseconds(_parameterValue(_udUqmaxIndex)),
      ),
      (
        label: labels.postBrakingTime,
        value: _formatReadableMilliseconds(_parameterValue(_warteHsaIndex)),
      ),
      (
        label: labels.peRelay,
        value: _formatReadablePeRelay(_parameterValue(_peRelaisIndex)),
      ),
      (
        label: labels.tachoMonitoring,
        value: _formatReadableMilliseconds(_parameterValue(_vzTaFahrtIndex)),
      ),
      (
        label: labels.phaseMonitoring,
        value: _formatReadableZeroOffMilliseconds(
          _parameterValue(_hsUeberwIndex),
        ),
      ),
    ];
    final labelWidth = rows.fold<int>(
      _readableLineLabelWidth,
      (width, row) => row.label.length > width ? row.label.length : width,
    );

    return <String>[
      for (final row in rows)
        '${row.label.padRight(labelWidth)} : ${row.value}',
    ];
  }

  List<String> _buildReadableDriveLines() {
    final labels = _readableDriveLabels();
    final rows = <({String label, String value})>[
      (
        label: labels.motorType,
        value: _formatReadableMotorType(_parameterValue(_motorTypIndex)),
      ),
      (
        label: labels.motorEncoder,
        value: _formatReadableMotorEncoder(_parameterValue(_geberSystemIndex)),
      ),
      (
        label: labels.feedbackPulses,
        value: _formatReadableRawInteger(_parameterValue(_inkStrichIndex)),
      ),
      (
        label: labels.pulseInput,
        value: _formatReadablePulseInput(_parameterValue(_geberAbrlIndex)),
      ),
      (
        label: labels.electricalRotatingField,
        value: _formatReadableElectricalRotatingField(
          _parameterValue(_geberAbrlIndex),
        ),
      ),
      (
        label: labels.syncPolePosition,
        value: _formatReadableRawInteger(_parameterValue(_syncPolIndex)),
      ),
      (
        label: labels.nameplateRatedSpeed,
        value: _formatReadableRawUnit(_parameterValue(_motDrehzIndex), 'UPM'),
      ),
      (
        label: labels.nameplateRatedFrequency,
        value: _formatReadableTenthsUnit(_parameterValue(_motFreqIndex), 'Hz'),
      ),
      (
        label: labels.nameplatePoleCount,
        value: _formatReadableNameplatePoleCount(),
      ),
      (
        label: labels.nameplateRatedCurrent,
        value: _formatReadableTenthsUnit(_parameterValue(_motStromIndex), 'A'),
      ),
      (
        label: labels.nameplateMotorRatedVoltage,
        value: _formatReadableRawUnit(_parameterValue(_uMotorIndex), 'V'),
      ),
      (
        label: labels.gearRatio,
        value: _formatReadableGearRatio(_parameterValue(_getUeberIndex)),
      ),
      (
        label: labels.tractionSheave,
        value: _formatReadableRawUnit(_parameterValue(_getTreibIndex), 'mm'),
      ),
      (
        label: labels.suspension,
        value: _formatReadableSuspension(_parameterValue(_getAufhIndex)),
      ),
      (
        label: labels.motorMagnetization,
        value: _formatReadablePercent(_parameterValue(_motMagIndex)),
      ),
      (
        label: labels.fieldWeakeningStart,
        value: _formatReadablePercent(_parameterValue(_feldEinIndex)),
      ),
      (
        label: labels.fieldWeakeningReduction,
        value: _formatReadablePercent(_parameterValue(_feldAbsIndex)),
      ),
      (
        label: labels.fieldWeakeningPt1,
        value: _formatReadableMilliseconds(_parameterValue(_feldPt1Index)),
      ),
      (
        label: labels.currentLimitRatedCurrent,
        value: _formatReadableTenths(_parameterValue(_stromBgrIndex)),
      ),
      (
        label: labels.motorThermistor,
        value: _formatReadableNonzeroOnOff(
          _parameterValue(_motKaltleiterIndex),
        ),
      ),
      (
        label: labels.igbtSwitchingFrequency,
        value: _formatReadableIgbtSwitchingFrequency(
          _parameterValue(_igbtTaktIndex),
        ),
      ),
      (
        label: labels.inspectionSwitchingFrequency,
        value: _formatReadableInspectionSwitchingFrequency(
          _parameterValue(_igbtTaktIndex),
        ),
      ),
    ];
    final labelWidth = rows.fold<int>(
      _readableLineLabelWidth,
      (width, row) => row.label.length > width ? row.label.length : width,
    );

    return <String>[
      for (final row in rows)
        '${row.label.padRight(labelWidth)} : ${row.value}',
    ];
  }

  _ReadableTravelCurveLabels _readableTravelCurveLabels() {
    switch (_exportLanguageCode()) {
      case 'de':
        return const _ReadableTravelCurveLabels(
          acceleration: 'Beschleunigung',
          accelerationJerk: 'Ruck-Beschleunigung',
          deceleration: 'Verzögerung',
          decelerationJerk: 'Ruck-Verzögerung',
          v1Optimization: 'V1 Bremsweg-Optimierung',
          v2Optimization: 'V2 Bremsweg-Optimierung',
          v3Optimization: 'V3 Bremsweg-Optimierung',
          peakCurve: 'Spitzbogen',
          maxBrakingRamp: 'max. Bremsrampe',
        );
      case 'fr':
        return const _ReadableTravelCurveLabels(
          acceleration: 'Accélération',
          accelerationJerk: 'À-coup accélération',
          deceleration: 'Décélération',
          decelerationJerk: 'À-coup décélération',
          v1Optimization: 'Optimisation distance de freinage V1',
          v2Optimization: 'Optimisation distance de freinage V2',
          v3Optimization: 'Optimisation distance de freinage V3',
          peakCurve: 'Courbe de pointe',
          maxBrakingRamp: 'Rampe de freinage max.',
        );
      case 'nl':
        return const _ReadableTravelCurveLabels(
          acceleration: 'Acceleratie',
          accelerationJerk: 'Ruk acceleratie',
          deceleration: 'Vertraging',
          decelerationJerk: 'Ruk vertraging',
          v1Optimization: 'V1 remwegoptimalisatie',
          v2Optimization: 'V2 remwegoptimalisatie',
          v3Optimization: 'V3 remwegoptimalisatie',
          peakCurve: 'Spitsboog',
          maxBrakingRamp: 'Max. remhelling',
        );
      case 'en':
      default:
        return const _ReadableTravelCurveLabels(
          acceleration: 'Acceleration',
          accelerationJerk: 'Acceleration jerk',
          deceleration: 'Deceleration',
          decelerationJerk: 'Deceleration jerk',
          v1Optimization: 'V1 braking distance optimization',
          v2Optimization: 'V2 braking distance optimization',
          v3Optimization: 'V3 braking distance optimization',
          peakCurve: 'Peak curve',
          maxBrakingRamp: 'Max. braking ramp',
        );
    }
  }

  _ReadableStartStopLabels _readableStartStopLabels() {
    switch (_exportLanguageCode()) {
      case 'de':
        return const _ReadableStartStopLabels(
          startDelay: 'Startverzögerung',
          brakingDistanceV0: 'Bremsweg V0 > 0',
          directLanding: 'Direkt Einfahrt',
          controllerBoostDcComponent: 'Regleranhebung Gleichstromanteil',
          controllerBoostPiValues: 'Regleranhebung P-I Werte',
          positionControl: 'Lageregelung',
          startControllerPComponent: 'Startregler P Anteil',
          startControllerIComponent: 'Startregler I Anteil',
          startControllerDComponent: 'Startregler D Anteil',
          startControllerFactor: 'Startregler Faktor',
          breakawaySpeed: 'Losreissen Drehzahl',
          breakawayDuration: 'Losreissen Dauer',
          hsWaitingTime: 'Wartezeit HS',
          nbsRunOnTime: 'NBS Nachlauf',
          postBrakingTime: 'Nachbremszeit',
          peRelay: 'PE Relais',
          tachoMonitoring: 'Tachoüberwachung',
          phaseMonitoring: 'Phasenüberwachung',
        );
      case 'fr':
        return const _ReadableStartStopLabels(
          startDelay: 'Temporisation de démarrage',
          brakingDistanceV0: 'Distance de freinage V0 > 0',
          directLanding: 'Entrée directe',
          controllerBoostDcComponent:
              'Composante courant continu de surélévation',
          controllerBoostPiValues: 'Valeurs P-I de surélévation',
          positionControl: 'Régulation de position',
          startControllerPComponent: 'Part P régulateur de démarrage',
          startControllerIComponent: 'Part I régulateur de démarrage',
          startControllerDComponent: 'Part D régulateur de démarrage',
          startControllerFactor: 'Facteur régulateur de démarrage',
          breakawaySpeed: 'Vitesse de décollage',
          breakawayDuration: 'Durée de décollage',
          hsWaitingTime: "Temps d'attente HS",
          nbsRunOnTime: 'Temporisation NBS',
          postBrakingTime: 'Temps de post-freinage',
          peRelay: 'Relais PE',
          tachoMonitoring: 'Surveillance tachymètre',
          phaseMonitoring: 'Surveillance de phase',
        );
      case 'nl':
        return const _ReadableStartStopLabels(
          startDelay: 'Startvertraging',
          brakingDistanceV0: 'Remweg V0 > 0',
          directLanding: 'Directe inrit',
          controllerBoostDcComponent: 'Regelaarverhoging DC-aandeel',
          controllerBoostPiValues: 'Regelaarverhoging P-I waarden',
          positionControl: 'Positieregeling',
          startControllerPComponent: 'Startregelaar P-aandeel',
          startControllerIComponent: 'Startregelaar I-aandeel',
          startControllerDComponent: 'Startregelaar D-aandeel',
          startControllerFactor: 'Startregelaar factor',
          breakawaySpeed: 'Losbreeksnelheid',
          breakawayDuration: 'Losbreekduur',
          hsWaitingTime: 'Wachttijd HS',
          nbsRunOnTime: 'NBS nalooptijd',
          postBrakingTime: 'Narem tijd',
          peRelay: 'PE-relais',
          tachoMonitoring: 'Tachobewaking',
          phaseMonitoring: 'Fasebewaking',
        );
      case 'en':
      default:
        return const _ReadableStartStopLabels(
          startDelay: 'Start delay',
          brakingDistanceV0: 'Braking distance V0 > 0',
          directLanding: 'Direct landing',
          controllerBoostDcComponent: 'Controller boost DC component',
          controllerBoostPiValues: 'Controller boost P-I values',
          positionControl: 'Position control',
          startControllerPComponent: 'Start controller P component',
          startControllerIComponent: 'Start controller I component',
          startControllerDComponent: 'Start controller D component',
          startControllerFactor: 'Start controller factor',
          breakawaySpeed: 'Breakaway speed',
          breakawayDuration: 'Breakaway duration',
          hsWaitingTime: 'HS waiting time',
          nbsRunOnTime: 'NBS run-on time',
          postBrakingTime: 'Post-braking time',
          peRelay: 'PE relay',
          tachoMonitoring: 'Tacho monitoring',
          phaseMonitoring: 'Phase monitoring',
        );
    }
  }

  _ReadableDriveLabels _readableDriveLabels() {
    switch (_exportLanguageCode()) {
      case 'de':
        return const _ReadableDriveLabels(
          motorType: 'Motor Allgemein',
          motorEncoder: 'Motor-Geber',
          feedbackPulses: 'Rückführung Impulse',
          pulseInput: 'Impulseingang',
          electricalRotatingField: 'Elektrisches Drehfeld',
          syncPolePosition: 'Sync. Pol-Lage',
          nameplateRatedSpeed: 'Typenschild Nenndrehzahl',
          nameplateRatedFrequency: 'Typenschild Nennfrequenz',
          nameplatePoleCount: 'Typenschild Polzahl',
          nameplateRatedCurrent: 'Typenschild Nennstrom',
          nameplateMotorRatedVoltage: 'Typenschild Motor Nennspannung',
          gearRatio: 'Getriebe Übersetzung',
          tractionSheave: 'Getriebe Treibscheibe',
          suspension: 'Aufhängung',
          motorMagnetization: 'Motormagnetisierung',
          fieldWeakeningStart: 'Feldschwäche Einsatz',
          fieldWeakeningReduction: 'Feldschwäche Abschwächung',
          fieldWeakeningPt1: 'Feldschwäche PT1',
          currentLimitRatedCurrent: 'Strombegrenzung Nennstrom',
          motorThermistor: 'Motor Kaltleiter',
          igbtSwitchingFrequency: 'IGBT Taktfrequenz',
          inspectionSwitchingFrequency: 'Inspektion Taktfrequenz',
        );
      case 'fr':
        return const _ReadableDriveLabels(
          motorType: 'Type moteur',
          motorEncoder: 'Codeur moteur',
          feedbackPulses: 'Impulsions de retour',
          pulseInput: 'Entrée impulsions',
          electricalRotatingField: 'Champ tournant électrique',
          syncPolePosition: 'Position pôle sync.',
          nameplateRatedSpeed: 'Vitesse nominale plaque',
          nameplateRatedFrequency: 'Fréquence nominale plaque',
          nameplatePoleCount: 'Nombre de pôles plaque',
          nameplateRatedCurrent: 'Courant nominal plaque',
          nameplateMotorRatedVoltage: 'Tension nominale moteur plaque',
          gearRatio: 'Rapport réducteur',
          tractionSheave: 'Poulie de traction',
          suspension: 'Suspension',
          motorMagnetization: 'Magnétisation moteur',
          fieldWeakeningStart: 'Début affaiblissement champ',
          fieldWeakeningReduction: 'Réduction affaiblissement champ',
          fieldWeakeningPt1: 'PT1 affaiblissement champ',
          currentLimitRatedCurrent: 'Limitation courant nominal',
          motorThermistor: 'Thermistance moteur',
          igbtSwitchingFrequency: 'Fréquence de commutation IGBT',
          inspectionSwitchingFrequency: 'Fréquence de commutation inspection',
        );
      case 'nl':
        return const _ReadableDriveLabels(
          motorType: 'Motortype',
          motorEncoder: 'Motor-encoder',
          feedbackPulses: 'Terugkoppelimpulsen',
          pulseInput: 'Impulsingang',
          electricalRotatingField: 'Elektrisch draaiveld',
          syncPolePosition: 'Sync. poolpositie',
          nameplateRatedSpeed: 'Typeplaat nominaal toerental',
          nameplateRatedFrequency: 'Typeplaat nominale frequentie',
          nameplatePoleCount: 'Typeplaat poolaantal',
          nameplateRatedCurrent: 'Typeplaat nominale stroom',
          nameplateMotorRatedVoltage: 'Typeplaat nominale motorspanning',
          gearRatio: 'Overbrengingsverhouding',
          tractionSheave: 'Tractieschijf',
          suspension: 'Ophanging',
          motorMagnetization: 'Motormagnetisatie',
          fieldWeakeningStart: 'Veldverzwakking inzet',
          fieldWeakeningReduction: 'Veldverzwakking reductie',
          fieldWeakeningPt1: 'Veldverzwakking PT1',
          currentLimitRatedCurrent: 'Stroombegrenzing nominale stroom',
          motorThermistor: 'Motor koudleider',
          igbtSwitchingFrequency: 'IGBT schakelfrequentie',
          inspectionSwitchingFrequency: 'Inspectie schakelfrequentie',
        );
      case 'en':
      default:
        return const _ReadableDriveLabels(
          motorType: 'Motor type',
          motorEncoder: 'Motor encoder',
          feedbackPulses: 'Feedback pulses',
          pulseInput: 'Pulse input',
          electricalRotatingField: 'Electrical rotating field',
          syncPolePosition: 'Sync. pole position',
          nameplateRatedSpeed: 'Nameplate rated speed',
          nameplateRatedFrequency: 'Nameplate rated frequency',
          nameplatePoleCount: 'Nameplate pole count',
          nameplateRatedCurrent: 'Nameplate rated current',
          nameplateMotorRatedVoltage: 'Nameplate motor rated voltage',
          gearRatio: 'Gear ratio',
          tractionSheave: 'Traction sheave',
          suspension: 'Suspension',
          motorMagnetization: 'Motor magnetization',
          fieldWeakeningStart: 'Field weakening start',
          fieldWeakeningReduction: 'Field weakening reduction',
          fieldWeakeningPt1: 'Field weakening PT1',
          currentLimitRatedCurrent: 'Current limit rated current',
          motorThermistor: 'Motor thermistor',
          igbtSwitchingFrequency: 'IGBT switching frequency',
          inspectionSwitchingFrequency: 'Inspection switching frequency',
        );
    }
  }

  String _formatReadableHundredths(int? value, String unit) {
    if (value == null) return '-';

    final isNegative = value < 0;
    final absoluteValue = value.abs();
    final whole = absoluteValue ~/ 100;
    final fraction = (absoluteValue % 100).toString().padLeft(2, '0');
    final separator = _exportLanguageCode() == 'en' ? '.' : ',';
    final sign = isNegative ? '-' : '';

    return '$sign$whole$separator$fraction $unit';
  }

  String _formatReadableTenthsUnit(int? value, String unit) {
    if (value == null) return '-';

    final isNegative = value < 0;
    final absoluteValue = value.abs();
    final whole = absoluteValue ~/ 10;
    final fraction = (absoluteValue % 10).toString();
    final separator = _exportLanguageCode() == 'en' ? '.' : ',';
    final sign = isNegative ? '-' : '';

    return '$sign$whole$separator$fraction $unit';
  }

  String _formatReadableTenths(int? value) {
    if (value == null) return '-';

    final isNegative = value < 0;
    final absoluteValue = value.abs();
    final whole = absoluteValue ~/ 10;
    final fraction = (absoluteValue % 10).toString();
    final separator = _exportLanguageCode() == 'en' ? '.' : ',';
    final sign = isNegative ? '-' : '';

    return '$sign$whole$separator$fraction';
  }

  String _formatReadableRawUnit(int? value, String unit) {
    if (value == null) return '-';
    return '$value $unit';
  }

  String _formatReadableMotorEncoder(int? value) {
    switch (value) {
      case null:
        return '-';
      case 1:
        return 'Asynch. Inkremental';
      case 2:
        return 'Asynch. open loop';
      case 3:
        return 'Synch. Endat';
      case 4:
        return 'Synch. Resolver';
      case 5:
        return 'Synch. SSI';
      case 6:
        return 'Synch. SinCos';
      case 7:
        return 'BissC';
      case 8:
        return 'Synch. Inkremental';
      case 9:
        return 'Synch. Hiperface';
      case 10:
        return 'Synch. BissC 21bit';
      case 11:
        return 'Synch. SSI 18bit';
      default:
        return value.toString();
    }
  }

  String _formatReadablePulseInput(int? value) {
    if (value == null) return '-';

    final ab = value & 0x0F;
    switch (ab) {
      case 0:
        return 'A-B';
      case 1:
        return 'B-A';
      default:
        return ab.toString();
    }
  }

  String _formatReadableElectricalRotatingField(int? value) {
    if (value == null) return '-';

    final rl = (value >> 4) & 0x0F;
    switch (rl) {
      case 0:
        return 'Links';
      case 1:
        return 'Rechts';
      default:
        return rl.toString();
    }
  }

  String _formatReadableMotorType(int? value) {
    if (value == null) return '-';

    final group = (value >> 8) & 0xFF;
    final type = value & 0xFF;
    final key = '$group.$type';
    final label = _readableMotorTypeLabels[key] ?? '-';

    return '$key - $label';
  }

  String _formatReadableNameplatePoleCount() {
    final motorFrequency = _parameterValue(_motFreqIndex);
    final motorSpeed = _parameterValue(_motDrehzIndex);

    if (motorFrequency == null || motorSpeed == null || motorSpeed == 0) {
      return '-';
    }

    final frequencyHz = motorFrequency / 10.0;
    final poles = (120 * frequencyHz / motorSpeed).round();
    return poles.toString();
  }

  String _formatReadableGearRatio(int? value) {
    if (value == null) return '-';
    return '1:${_formatReadableTenths(value)}';
  }

  String _formatReadableSuspension(int? value) {
    if (value == null) return '-';
    return '1:$value';
  }

  String _formatReadableNonzeroOnOff(int? value) {
    if (value == null) return '-';
    return value == 0
        ? _localizedValue(de: 'AUS', en: 'OFF', fr: 'ARRÊT', nl: 'UIT')
        : _localizedValue(de: 'EIN', en: 'ON', fr: 'MARCHE', nl: 'AAN');
  }

  String _formatReadableIgbtSwitchingFrequency(int? value) {
    if (value == null) return '-';

    final nibble = value & 0x0F;
    return _igbtSwitchingFrequencyLabels[nibble] ?? '-';
  }

  String _formatReadableInspectionSwitchingFrequency(int? value) {
    if (value == null) return '-';

    final nibble = (value >> 4) & 0x0F;
    return _inspectionSwitchingFrequencyLabels[nibble] ?? '-';
  }

  String _formatReadableMilliseconds(int? value) {
    if (value == null) return '-';
    return '$value ms';
  }

  String _formatReadableAutoOrMs(int? value) {
    if (value == null) return '-';
    if (value == 0) {
      return _localizedValue(de: 'Auto', en: 'Auto', fr: 'Auto', nl: 'Auto');
    }
    return '$value ms';
  }

  String _formatReadableRawInteger(int? value) {
    if (value == null) return '-';
    return value.toString();
  }

  String _formatReadablePercent(int? value) {
    if (value == null) return '-';
    return '$value %';
  }

  String _formatReadableDirectLanding(int? value) {
    if (value == null) return '-';

    switch (value) {
      case 0:
        return _localizedValue(de: 'AUS', en: 'OFF', fr: 'ARRÊT', nl: 'UIT');
      case 1:
        return _localizedValue(de: 'EIN', en: 'ON', fr: 'MARCHE', nl: 'AAN');
      case 2:
        return _localizedValue(
          de: 'ohne V0',
          en: 'without V0',
          fr: 'sans V0',
          nl: 'zonder V0',
        );
      default:
        return '-';
    }
  }

  String _formatReadableLageregelung(int? value) {
    final start1T = value;
    final passwort = _parameterValue(_passwortIndex);

    if (start1T == null || passwort == null) return '-';

    if ((passwort & (1 << 10)) != 0) {
      return _localizedValue(
        de: 'adaptiv',
        en: 'adaptive',
        fr: 'adaptatif',
        nl: 'adaptief',
      );
    }

    if ((start1T & (1 << 5)) != 0) {
      return _localizedValue(
        de: 'Wegabhängig',
        en: 'Distance-dependent',
        fr: 'Dépendant de la distance',
        nl: 'Afstandsafhankelijk',
      );
    }

    return _localizedValue(de: 'AUS', en: 'OFF', fr: 'ARRÊT', nl: 'UIT');
  }

  String _formatReadableZeroOffMilliseconds(int? value) {
    if (value == null) return '-';
    if (value == 0) {
      return _localizedValue(de: 'AUS', en: 'OFF', fr: 'ARRÊT', nl: 'UIT');
    }
    return '$value ms';
  }

  String _formatReadablePeRelay(int? value) {
    if (value == null) return '-';

    switch (value) {
      case 0:
        return _localizedValue(de: 'AUS', en: 'OFF', fr: 'ARRÊT', nl: 'UIT');
      case 1:
        return _localizedValue(de: 'EIN', en: 'ON', fr: 'MARCHE', nl: 'AAN');
      case 2:
        return _localizedValue(
          de: 'aus beim Stillstand',
          en: 'off at standstill',
          fr: "arrêt à l'arrêt",
          nl: 'uit bij stilstand',
        );
      default:
        return '$value ms';
    }
  }

  String _formatReadableMessfahrtState(int shift) {
    final messfahrt = _parameterValue(_messfahrtIndex);
    if (messfahrt == null) return '-';

    final state = (messfahrt >> shift) & 0x03;
    switch (state) {
      case 0:
        return _localizedValue(de: 'AUS', en: 'OFF', fr: 'ARRÊT', nl: 'UIT');
      case 1:
        return _localizedValue(de: 'EIN', en: 'ON', fr: 'MARCHE', nl: 'AAN');
      case 2:
        return _localizedValue(
          de: 'Messfahrt',
          en: 'Measuring run',
          fr: 'Course de mesure',
          nl: 'Meetrit',
        );
      default:
        return '-';
    }
  }

  String _formatReadableSpitzfunc(int? value) {
    switch (value) {
      case 0:
        return _localizedValue(
          de: 'Wegorientiert',
          en: 'Distance-oriented',
          fr: 'Orienté distance',
          nl: 'Afstandsgericht',
        );
      case 1:
        return _localizedValue(
          de: 'Geschwindigkeitsorientiert',
          en: 'Speed-oriented',
          fr: 'Orienté vitesse',
          nl: 'Snelheidsgericht',
        );
      case 2:
        return 'V3-V2-V1-V0';
      case 3:
        return 'V0-V1-V2-V3';
      default:
        return '-';
    }
  }

  String _localizedValue({
    required String de,
    required String en,
    required String fr,
    required String nl,
  }) {
    switch (_exportLanguageCode()) {
      case 'de':
        return de;
      case 'fr':
        return fr;
      case 'nl':
        return nl;
      case 'en':
      default:
        return en;
    }
  }

  String _readableBrakeDistanceSuffixLabel() {
    switch (_exportLanguageCode()) {
      case 'de':
        return 'Bremsweg -> V0';
      case 'fr':
        return 'Distance de freinage -> V0';
      case 'nl':
        return 'Remweg -> V0';
      case 'en':
      default:
        return 'Braking distance -> V0';
    }
  }

  int? _calculateBrakeDistanceToV0Mm(int speedIndex) {
    final speedUpm = _parameterValue(speedIndex);
    final speedV0Upm = _parameterValue(_geschwV0Index);
    final deceleration = _parameterValue(_verzoeIndex);
    final jerk = _parameterValue(_ruckVerzIndex);
    final brakeDistanceV0 = _parameterValue(_bremswegV0Index);
    final getUeber = _parameterValue(_getUeberIndex);
    final getTreib = _parameterValue(_getTreibIndex);
    final getAufh = _parameterValue(_getAufhIndex);

    if (speedUpm == null ||
        speedV0Upm == null ||
        deceleration == null ||
        jerk == null ||
        brakeDistanceV0 == null ||
        getUeber == null ||
        getTreib == null ||
        getAufh == null) {
      return null;
    }

    if (deceleration == 0 || jerk == 0 || getUeber == 0 || getAufh == 0) {
      return null;
    }

    const fixedScale = 1000000;
    const piFixed = 3141593;

    int sqrtFixed(int value) {
      if (value <= 0) return 0;

      var root = value;
      var next = (root + 1) ~/ 2;
      while (next < root) {
        root = next;
        next = (root + value ~/ root) ~/ 2;
      }
      return root;
    }

    int rpmToVelocityMmPerSecondFixed(int upm) {
      var velocity = upm * getTreib * piFixed;
      velocity ~/= getUeber;
      velocity ~/= getAufh * 60;
      return velocity;
    }

    int upmToMmPerSecond(int upm) {
      var mmPerSecond = upm * getTreib;
      mmPerSecond ~/= getAufh * getUeber * 10;
      mmPerSecond = (mmPerSecond * 1072) >> 11;
      return mmPerSecond;
    }

    final maxVelocity = rpmToVelocityMmPerSecondFixed(speedUpm - speedV0Upm);
    final minVelocity = rpmToVelocityMmPerSecondFixed(speedV0Upm);
    final acceleration = deceleration * 10 * fixedScale;
    final jerkVelocity = jerk * 10 * fixedScale;
    final jerkLimitVelocity =
        (acceleration * acceleration) ~/ (2 * jerkVelocity);

    final restWay = jerkLimitVelocity * 2 > maxVelocity
        ? (maxVelocity + 2 * minVelocity) *
              sqrtFixed(
                (maxVelocity * fixedScale ~/ jerkVelocity) * fixedScale,
              ) ~/
              fixedScale
        : (maxVelocity ~/ 2 + minVelocity) *
              (maxVelocity * fixedScale ~/ acceleration +
                  acceleration * fixedScale ~/ jerkVelocity) ~/
              fixedScale;

    var way = (restWay ~/ fixedScale) & 0xFFFF;
    way = (way + upmToMmPerSecond(speedV0Upm) ~/ 2) & 0xFFFF;
    way = (way + brakeDistanceV0 ~/ 10) & 0xFFFF;
    return way;
  }

  String _formatUpm(int value) {
    //return '${value.toString().padLeft(4, '0')},0';
    final whole = value ~/ 10;
    final decimal = value.abs() % 10;
    return '${whole.toString().padLeft(4, '0')},$decimal';
  }

  double? _upmToMetersPerSecond(int upm) {
    final getUeber = _parameterValue(_getUeberIndex);
    final getTreib = _parameterValue(_getTreibIndex);
    final getAufh = _parameterValue(_getAufhIndex);
    if (getUeber == null || getTreib == null || getAufh == null) return null;

    var mps = _uint32(upm);
    mps = _uint32(mps * getTreib);
    final denominator = getAufh * getUeber * 10;
    if (denominator != 0) {
      mps ~/= denominator;
    }

    mps = _uint32(mps * 1072);
    mps = mps >> 11;

    return mps / 1000.0;
  }

  int _uint32(int value) {
    return value & 0xFFFFFFFF;
  }

  String _formatMetersPerSecond(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatExportDateTime(DateTime value) {
    final date =
        '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';

    return '$date $time';
  }

  String _buildTxtExportFileName() {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    return 'fb10_parameters_${date}_$time.txt';
  }

  String _parameterNameForIndex(int index) {
    if (index < _rtcDspRamFieldNames.length) {
      final name = _rtcDspRamFieldNames[index];
      if (name.isNotEmpty) return name;
    }

    return 'Param_${index.toString().padLeft(3, '0')}';
  }

  String _formatWord(int value) {
    return '0x${(value & 0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase()}';
  }

  int get _expectedPacketCount {
    if (_useEepromOnlyDownload) return _eepromWords.length;
    return _expectedLastIndex + 1;
  }

  int get _displayPacketCount {
    if (_useEepromOnlyDownload) return _displayEepromPacketCount;
    return _packetCount.clamp(0, _expectedPacketCount).toInt();
  }

  double get _downloadProgress {
    if (_expectedPacketCount == 0) return 0;
    return (_displayPacketCount / _expectedPacketCount).clamp(0, 1).toDouble();
  }

  int get _downloadPercent {
    return (_downloadProgress * 100).round();
  }

  int get _displayEepromPacketCount {
    return _eepromPacketCount.clamp(0, _eepromWords.length).toInt();
  }

  bool get _canCloseScreen {
    return _driverReady &&
        !_waitingForHandshakeBb &&
        !_eepromReadStarted &&
        (!_useEepromOnlyDownload || _eepromReadComplete);
  }

  Future<void> _closeScreen() async {
    if (!_canCloseScreen) {
      debugPrint('PARAM close blocked; driver not ready');
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final materialL10n = MaterialLocalizations.of(context);
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? 24.0
        : 16.0;

    return Scaffold(
      backgroundColor: _screenBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: _accentColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 72,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.parametersTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: materialL10n.closeButtonTooltip,
            icon: const Icon(Icons.close),
            onPressed: _canCloseScreen ? _closeScreen : null,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(context, l10n),
                  const SizedBox(height: 12),
                  _buildProgressCard(context, l10n),
                  if (_downloadComplete) ...[
                    const SizedBox(height: 12),
                    _buildExportCard(context, l10n),
                    const SizedBox(height: 12),
                    _buildPreviewCard(context, l10n),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, AppLocalizations l10n) {
    final lastEepromAddress = _lastEepromAddress == null
        ? '-'
        : '${_lastEepromAddress!} value ${_lastEepromValue ?? '-'}';
    final lastParameter = _useEepromOnlyDownload
        ? lastEepromAddress
        : _lastIndex?.toString() ?? l10n.noParameter;
    final eepromCompleteText = _eepromReadComplete ? 'true' : 'false';
    final connectionText = _driverReady
        ? l10n.connectionReady
        : l10n.connectionWaiting;
    final exportText = _txtExport == null
        ? l10n.exportPreparing
        : l10n.exportReady;

    return _buildSectionCard(
      child: Column(
        children: [
          _buildStatusRow(
            context,
            label: l10n.downloadedPackets,
            value: l10n.parameterProgressValue(
              _displayPacketCount,
              _expectedPacketCount,
            ),
          ),
          _buildStatusDivider(),
          _buildStatusRow(
            context,
            label: l10n.lastParameter,
            value: lastParameter,
          ),
          _buildStatusDivider(),
          _buildStatusRow(
            context,
            label: 'EEPROM packets',
            value: '$_displayEepromPacketCount / ${_eepromWords.length}',
          ),
          _buildStatusDivider(),
          _buildStatusRow(
            context,
            label: 'Last EEPROM address',
            value: lastEepromAddress,
          ),
          _buildStatusDivider(),
          _buildStatusRow(
            context,
            label: 'EEPROM complete',
            value: eepromCompleteText,
            color: _eepromReadComplete ? _readyColor : _pendingColor,
          ),
          _buildStatusDivider(),
          _buildStatusRow(
            context,
            label: l10n.connection,
            value: connectionText,
            color: _driverReady ? _readyColor : _pendingColor,
          ),
          _buildStatusDivider(),
          _buildStatusRow(
            context,
            label: l10n.export,
            value: exportText,
            color: _txtExport == null ? _pendingColor : _readyColor,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n.downloadProgress,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF172033),
                  ),
                ),
              ),
              Text(
                l10n.percentComplete(_downloadPercent),
                style: textTheme.titleMedium?.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE4EAF2),
              valueColor: const AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.parameterProgressValue(
              _displayPacketCount,
              _expectedPacketCount,
            ),
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, AppLocalizations l10n) {
    final textTheme = Theme.of(context).textTheme;

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: _accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.txtExportReady,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF172033),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.exportDescription,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.35,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSaveTxt ? _shareTxtExport : null,
              icon: const Icon(Icons.save_alt),
              label: Text(l10n.saveTxt),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE1E7EF),
                disabledForegroundColor: const Color(0xFF8793A3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, AppLocalizations l10n) {
    final previewText = _txtExport ?? '';
    final previewMaxHeight = (MediaQuery.sizeOf(context).height * 0.45)
        .clamp(160.0, 420.0)
        .toDouble();

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.preview,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: previewMaxHeight),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: _cardBorderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Scrollbar(
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  primary: false,
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    previewText,
                    style: const TextStyle(
                      color: Color(0xFF253143),
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _cardBorderColor),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? color,
  }) {
    final valueColor = color ?? const Color(0xFF253143);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildStatusBadge(value, valueColor),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildStatusDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: _cardBorderColor),
    );
  }
}

class _ParameterDescriptor {
  final int index;
  final String parameter;
  final String label;
  final _ReadableParameterCategory category;

  const _ParameterDescriptor({
    required this.index,
    required this.parameter,
    required this.label,
    required this.category,
  });
}

class _ReadableTravelCurveLabels {
  final String acceleration;
  final String accelerationJerk;
  final String deceleration;
  final String decelerationJerk;
  final String v1Optimization;
  final String v2Optimization;
  final String v3Optimization;
  final String peakCurve;
  final String maxBrakingRamp;

  const _ReadableTravelCurveLabels({
    required this.acceleration,
    required this.accelerationJerk,
    required this.deceleration,
    required this.decelerationJerk,
    required this.v1Optimization,
    required this.v2Optimization,
    required this.v3Optimization,
    required this.peakCurve,
    required this.maxBrakingRamp,
  });
}

class _ReadableStartStopLabels {
  final String startDelay;
  final String brakingDistanceV0;
  final String directLanding;
  final String controllerBoostDcComponent;
  final String controllerBoostPiValues;
  final String positionControl;
  final String startControllerPComponent;
  final String startControllerIComponent;
  final String startControllerDComponent;
  final String startControllerFactor;
  final String breakawaySpeed;
  final String breakawayDuration;
  final String hsWaitingTime;
  final String nbsRunOnTime;
  final String postBrakingTime;
  final String peRelay;
  final String tachoMonitoring;
  final String phaseMonitoring;

  const _ReadableStartStopLabels({
    required this.startDelay,
    required this.brakingDistanceV0,
    required this.directLanding,
    required this.controllerBoostDcComponent,
    required this.controllerBoostPiValues,
    required this.positionControl,
    required this.startControllerPComponent,
    required this.startControllerIComponent,
    required this.startControllerDComponent,
    required this.startControllerFactor,
    required this.breakawaySpeed,
    required this.breakawayDuration,
    required this.hsWaitingTime,
    required this.nbsRunOnTime,
    required this.postBrakingTime,
    required this.peRelay,
    required this.tachoMonitoring,
    required this.phaseMonitoring,
  });
}

class _ReadableDriveLabels {
  final String motorType;
  final String motorEncoder;
  final String feedbackPulses;
  final String pulseInput;
  final String electricalRotatingField;
  final String syncPolePosition;
  final String nameplateRatedSpeed;
  final String nameplateRatedFrequency;
  final String nameplatePoleCount;
  final String nameplateRatedCurrent;
  final String nameplateMotorRatedVoltage;
  final String gearRatio;
  final String tractionSheave;
  final String suspension;
  final String motorMagnetization;
  final String fieldWeakeningStart;
  final String fieldWeakeningReduction;
  final String fieldWeakeningPt1;
  final String currentLimitRatedCurrent;
  final String motorThermistor;
  final String igbtSwitchingFrequency;
  final String inspectionSwitchingFrequency;

  const _ReadableDriveLabels({
    required this.motorType,
    required this.motorEncoder,
    required this.feedbackPulses,
    required this.pulseInput,
    required this.electricalRotatingField,
    required this.syncPolePosition,
    required this.nameplateRatedSpeed,
    required this.nameplateRatedFrequency,
    required this.nameplatePoleCount,
    required this.nameplateRatedCurrent,
    required this.nameplateMotorRatedVoltage,
    required this.gearRatio,
    required this.tractionSheave,
    required this.suspension,
    required this.motorMagnetization,
    required this.fieldWeakeningStart,
    required this.fieldWeakeningReduction,
    required this.fieldWeakeningPt1,
    required this.currentLimitRatedCurrent,
    required this.motorThermistor,
    required this.igbtSwitchingFrequency,
    required this.inspectionSwitchingFrequency,
  });
}

enum _ReadableParameterCategory {
  speed,
  travelCurve,
  startStop,
  drive,
  interfaces,
  operatingParameters,
  controllerParameters,
  tuvMenu,
  hardware,
  internalTimings,
  miscellaneous,
}
