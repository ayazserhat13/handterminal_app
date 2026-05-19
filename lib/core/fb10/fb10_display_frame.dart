
class Fb10DisplayFrame {
  static const int displayByteCount = 64;
  static const int frameByteCount = 65;
  static const int lineCount = 4;
  static const int charsPerLine = 16;

  final List<String> lines;
  final int status;

  const Fb10DisplayFrame({required this.lines, required this.status});

  bool get errorLed => (status & 0x02) != 0;
  bool get operateLed => (status & 0x01) != 0;
}
