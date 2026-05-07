import 'package:flutter_test/flutter_test.dart';
import 'package:handterminal_app/core/fb10/fb10_display_decoder.dart';

void main() {
  const decoder = Fb10DisplayDecoder();

  test('decodes ASCII and FB10 special characters', () {
    final bytes = <int>[0, 1, 2, 239, 245, 225, 223, ...'ABC'.codeUnits];

    final decoded = decoder.decodeScreen(bytes);

    expect(decoded, startsWith('↕↑↓öüä°ABC'));
    expect(decoded.length, 64);
  });

  test('splits 64 display bytes into four 16-character lines', () {
    final bytes = <int>[
      ...'ABCDEFGHIJKLMNOP'.codeUnits,
      ...'QRSTUVWXYZ123456'.codeUnits,
      ...'abcdefghijklmnop'.codeUnits,
      ...'qrstuvwxyz789012'.codeUnits,
    ];

    final lines = decoder.decodeLines(bytes);

    expect(lines, [
      'ABCDEFGHIJKLMNOP',
      'QRSTUVWXYZ123456',
      'abcdefghijklmnop',
      'qrstuvwxyz789012',
    ]);
  });
}
