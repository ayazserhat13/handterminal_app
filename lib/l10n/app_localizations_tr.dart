// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Handterminal App';

  @override
  String get screenTitle => 'TFT Ekran Simülasyonu';

  @override
  String get menu => 'MENÜ';

  @override
  String get display => 'Ekran';

  @override
  String get graph => 'Grafik';

  @override
  String get connection => 'Bağlantı';

  @override
  String get settings => 'Ayarlar';

  @override
  String get monitoring => 'İzleme';

  @override
  String get errors => 'Hatalar';

  @override
  String get info => 'Bilgi';

  @override
  String get quit => 'Çık';

  @override
  String get down => 'Aşağı';

  @override
  String get up => 'Yukarı';

  @override
  String get enter => 'Enter';

  @override
  String get lcdLineHello => 'Merhaba Dünya!';

  @override
  String get lcdLineFloor => 'Kat: 3 Yukarı ';

  @override
  String get lcdLineReady => 'Sistem Hazır..';

  @override
  String get lcdLineNoError => 'Hata Yok      ';

  @override
  String get fb10Display => 'FB10 Ekran';

  @override
  String get errorLed => 'HATA';

  @override
  String get operateLed => 'ÇALIŞMA';

  @override
  String get monitor => 'Monitör';

  @override
  String get ab => 'AŞAĞI';

  @override
  String get auf => 'YUKARI';

  @override
  String get statusPreparingConnection => 'Bağlantı hazırlanıyor...';

  @override
  String get statusHandshakeStarting => 'Handshake başlatılıyor...';

  @override
  String get statusWaitingForBb => '0xBB bekleniyor...';

  @override
  String get statusFirstBbReceived => 'İlk 0xBB alındı, 0xAA gönderiliyor...';

  @override
  String get statusSecondBbReceived =>
      'İkinci 0xBB alındı, terminal başlatılıyor...';

  @override
  String get statusTerminalReady => 'Terminal hazır';

  @override
  String get statusKeySendError => 'Tuş gönderme hatası';

  @override
  String get statusBbTimeout => 'Zaman aşımı: 0xBB alınmadı';

  @override
  String statusHandshakeError(Object error) {
    return 'Handshake hatası: $error';
  }

  @override
  String statusTerminalStartError(Object error) {
    return 'Terminal başlatma hatası: $error';
  }

  @override
  String get homeConnect => 'Bağlan';

  @override
  String get homeTerminal => 'Terminal';

  @override
  String get homeSpeedCurve => 'Hız Eğrisi';

  @override
  String get homeSoftwareUpdate => 'Yazılım Güncelleme';

  @override
  String get homeDownloadErrors => 'Hataları İndir';

  @override
  String get homeDownloadParameters => 'Parametreleri İndir';

  @override
  String get homeUploadParameters => 'Parametre Yükle';

  @override
  String get homeDocuments => 'Dokümanlar';

  @override
  String get homeAbout => 'Hakkında';

  @override
  String get homeNotConnected => 'Bağlı değil';

  @override
  String get homeConnectHint => 'Lütfen Bluetooth ile cihaza bağlanın.';

  @override
  String get bluetoothTitle => 'Bluetooth Bağlantısı';

  @override
  String get bluetoothReady => 'Hazır';

  @override
  String get bluetoothScanning => 'Cihazlar aranıyor...';

  @override
  String get bluetoothScanComplete => 'Arama tamamlandı';

  @override
  String get bluetoothNoDevicesFound => 'Cihaz bulunamadı';

  @override
  String get bluetoothUnknownDevice => 'Bilinmeyen Cihaz';

  @override
  String get bluetoothScan => 'Ara';

  @override
  String get bluetoothStop => 'Durdur';

  @override
  String get bluetoothNotSupported => 'Bu cihaz BLE desteklemiyor';

  @override
  String get bluetoothScanError => 'Arama hatası';

  @override
  String get bluetoothStopError => 'Durdurma hatası';

  @override
  String get bluetoothStopped => 'Arama durduruldu';

  @override
  String bluetoothConnecting(Object deviceName) {
    return '$deviceName cihazına bağlanılıyor...';
  }

  @override
  String get bluetoothMissingCharacteristics =>
      'Bağlandı, ancak gerekli karakteristikler bulunamadı';

  @override
  String get bluetoothConnectionError => 'Bağlantı hatası';

  @override
  String get bluetoothConnectionLost => 'Bluetooth bağlantısı koptu';

  @override
  String get bluetoothTurnOnRequired => 'Bluetooth açık olmalı';

  @override
  String get bluetoothReconnecting => 'Yeniden bağlanılıyor...';

  @override
  String get parametersTitle => 'Parametreler';

  @override
  String get parameterExportSubtitle => 'FB10 parametre dışa aktarımı';

  @override
  String get downloadedPackets => 'İndirilen paketler';

  @override
  String get lastParameter => 'Son parametre';

  @override
  String get connectionReady => 'Hazır';

  @override
  String get connectionWaiting => 'Bekleniyor';

  @override
  String get export => 'Dışa aktarım';

  @override
  String get exportReady => 'Hazır';

  @override
  String get exportPreparing => 'Hazırlanıyor';

  @override
  String get txtExportReady => 'TXT dışa aktarımı hazır';

  @override
  String get exportDescription =>
      'Dışa aktarılan parametre dosyası kaydedilebilir veya paylaşılabilir.';

  @override
  String get saveTxt => 'TXT Kaydet';

  @override
  String get preview => 'Önizleme';

  @override
  String get downloadProgress => 'İndirme ilerlemesi';

  @override
  String parameterProgressValue(int current, int total) {
    return '$current / $total';
  }

  @override
  String percentComplete(int percent) {
    return '%$percent';
  }

  @override
  String get noParameter => '—';
}
