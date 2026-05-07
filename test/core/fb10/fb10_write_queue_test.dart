import 'dart:async';
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:handterminal_app/core/fb10/fb10_write_queue.dart';

void main() {
  test('serializes writes in enqueue order', () async {
    final startedWrites = <int>[];
    final releaseWrites = Queue<Completer<void>>();

    final queue = Fb10WriteQueue(
      writer: (bytes) {
        startedWrites.add(bytes.single);

        final completer = Completer<void>();
        releaseWrites.add(completer);
        return completer.future;
      },
    );

    final firstWrite = queue.enqueue(const [1]);
    final secondWrite = queue.enqueue(const [2]);

    await Future<void>.delayed(Duration.zero);

    expect(queue.isBusy, isTrue);
    expect(startedWrites, [1]);

    releaseWrites.removeFirst().complete();
    await firstWrite;
    await Future<void>.delayed(Duration.zero);

    expect(startedWrites, [1, 2]);

    releaseWrites.removeFirst().complete();
    await secondWrite;

    expect(queue.isBusy, isFalse);
  });

  test('close completes queued writes without starting them', () async {
    final startedWrites = <int>[];
    final releaseFirstWrite = Completer<void>();

    final queue = Fb10WriteQueue(
      writer: (bytes) {
        startedWrites.add(bytes.single);
        return releaseFirstWrite.future;
      },
    );

    final firstWrite = queue.enqueue(const [1]);
    final secondWrite = queue.enqueue(const [2]);

    await Future<void>.delayed(Duration.zero);
    queue.close();

    await secondWrite;
    expect(startedWrites, [1]);

    releaseFirstWrite.complete();
    await firstWrite;

    expect(queue.isBusy, isFalse);
  });
}
