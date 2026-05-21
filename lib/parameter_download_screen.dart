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
  static const Duration _keepaliveInterval = Duration(milliseconds: 250);
  static const Color _accentColor = Color(0xFF0A4C93);
  static const Color _readyColor = Color(0xFF0F7B4B);
  static const Color _pendingColor = Color(0xFF64748B);
  static const Color _screenBackground = Color(0xFFF4F7FA);
  static const Color _cardBorderColor = Color(0xFFE1E7EF);
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

  late final Fb10WriteQueue _writeQueue;
  StreamSubscription<List<int>>? _notifySub;
  Future<void> _notifyChain = Future<void>.value();
  Timer? _keepaliveTimer;
  Timer? _handshakeTimer;

  int _packetCount = 0;
  int? _lastIndex;
  String? _txtExport;
  List<String> _txtPreviewLines = <String>[];
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
    _parameters.clear();

    if (mounted) {
      setState(() {
        _packetCount = 0;
        _lastIndex = null;
        _txtExport = null;
        _txtPreviewLines = <String>[];
        _downloadComplete = false;
        _driverReady = false;
      });
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

    if (_downloadComplete) {
      _handleKeepaliveNotify(value);
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

  void _handleKeepaliveNotify(List<int> value) {
    if (!value.contains(Fb10Commands.handshakeResponse)) return;

    debugPrint('PARAM RX 0xBB ready');

    if (mounted) {
      setState(() {
        _driverReady = true;
      });
    } else {
      _driverReady = true;
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
    final txtExport = _buildRawTxtExport();
    final previewLines = txtExport.split('\n').take(10).toList();
    debugPrint('PARAM TXT PREVIEW:\n${previewLines.join('\n')}');

    if (mounted) {
      setState(() {
        _txtExport = txtExport;
        _txtPreviewLines = previewLines;
        _downloadComplete = true;
      });
    } else {
      _txtExport = txtExport;
      _txtPreviewLines = previewLines;
      _downloadComplete = true;
    }

    _startKeepalive();
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

  bool get _canSaveTxt {
    return _downloadComplete && _driverReady && _txtExport != null;
  }

  Future<void> _shareTxtExport() async {
    if (!_canSaveTxt) return;

    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _writeQueue.clearPending();
    debugPrint('PARAM keepalive paused for share');

    try {
      final txtExport = _buildRawTxtExport();
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

  Future<void> _restartHandshakeAfterShare() async {
    if (_disposed) return;

    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _writeQueue.clearPending();
    _waitingForHandshakeBb = true;
    _handshakeTryCount = 0;
    debugPrint('PARAM handshake restart after share');

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
    return _expectedLastIndex + 1;
  }

  int get _displayPacketCount {
    return _packetCount.clamp(0, _expectedPacketCount).toInt();
  }

  double get _downloadProgress {
    if (_expectedPacketCount == 0) return 0;
    return (_displayPacketCount / _expectedPacketCount).clamp(0, 1).toDouble();
  }

  int get _downloadPercent {
    return (_downloadProgress * 100).round();
  }

  bool get _canCloseScreen {
    return _driverReady && !_waitingForHandshakeBb;
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: _accentColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 72,
        leading: IconButton(
          tooltip: materialL10n.backButtonTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: _canCloseScreen ? _closeScreen : null,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.parametersTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.parameterExportSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
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
    final lastParameter = _lastIndex?.toString() ?? l10n.noParameter;
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
    final previewText = _txtPreviewLines.join('\n');

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
            constraints: const BoxConstraints(maxHeight: 190),
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
