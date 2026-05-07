import 'dart:convert';

import 'fb10_display_frame.dart';

class Fb10DisplayDecoder {
  const Fb10DisplayDecoder();

  List<String> decodeLines(List<int> bytes) {
    final decoded = decodeScreen(bytes);

    return [
      decoded.substring(0, 16),
      decoded.substring(16, 32),
      decoded.substring(32, 48),
      decoded.substring(48, 64),
    ];
  }

  String decodeScreen(List<int> bytes) {
    final chars = <String>[];

    for (final b in bytes) {
      final signedByte = b >= 128 ? b - 256 : b;

      switch (signedByte) {
        case 0:
          chars.add('↕');
          break;
        case 1:
          chars.add('↑');
          break;
        case 2:
          chars.add('↓');
          break;
        case -17:
          chars.add('ö');
          break;
        case -11:
          chars.add('ü');
          break;
        case -31:
          chars.add('ä');
          break;
        case -33:
          chars.add('°');
          break;
        default:
          if (b >= 32 && b <= 126) {
            chars.add(ascii.decode([b]));
          } else {
            chars.add(' ');
          }
      }
    }

    return chars
        .join()
        .padRight(Fb10DisplayFrame.displayByteCount)
        .substring(0, Fb10DisplayFrame.displayByteCount);
  }
}
