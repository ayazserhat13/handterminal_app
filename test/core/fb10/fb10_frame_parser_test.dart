import 'package:flutter_test/flutter_test.dart';
import 'package:handterminal_app/core/fb10/fb10_frame_parser.dart';

void main() {
  List<int> buildFrame({
    String text =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ123456abcdefghijklmnopqrstuvwxyz789012',
    int status = 0x50,
  }) {
    final displayBytes = text.padRight(64).substring(0, 64).codeUnits;
    return <int>[...displayBytes, status];
  }

  test('returns no frame until 65 bytes are buffered', () {
    final parser = Fb10FrameParser();
    final frame = buildFrame();

    expect(parser.addBytes(frame.sublist(0, 20)), isEmpty);
    expect(parser.bufferedByteCount, 20);

    final frames = parser.addBytes(frame.sublist(20));

    expect(frames, hasLength(1));
    expect(frames.single.lines.first, 'ABCDEFGHIJKLMNOP');
    expect(parser.bufferedByteCount, 0);
  });

  test('parses status byte into led flags', () {
    final parser = Fb10FrameParser();
    final frames = parser.addBytes(buildFrame(status: 0x53));

    expect(frames, hasLength(1));
    expect(frames.single.errorLed, isTrue);
    expect(frames.single.operateLed, isTrue);
  });

  test('skips leading junk before a valid frame', () {
    final parser = Fb10FrameParser();
    final frames = parser.addBytes(<int>[
      0x99,
      0x88,
      0x77,
      ...buildFrame(status: 0x51),
    ]);

    expect(frames, hasLength(1));
    expect(frames.single.lines.first, 'ABCDEFGHIJKLMNOP');
    expect(frames.single.errorLed, isFalse);
    expect(frames.single.operateLed, isTrue);
  });

  test('drops a leading status byte when next 65 bytes form a valid frame', () {
    final parser = Fb10FrameParser();
    final frames = parser.addBytes(<int>[0x50, ...buildFrame(status: 0x52)]);

    expect(frames, hasLength(1));
    expect(frames.single.errorLed, isTrue);
    expect(frames.single.operateLed, isFalse);
  });
}
