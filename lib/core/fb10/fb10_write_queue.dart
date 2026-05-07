import 'dart:async';
import 'dart:collection';

typedef Fb10ByteWriter = Future<void> Function(List<int> bytes);

class Fb10WriteQueue {
  final Fb10ByteWriter _writer;
  final Queue<_QueuedWrite> _queue = Queue<_QueuedWrite>();

  bool _isWriting = false;
  bool _isClosed = false;

  Fb10WriteQueue({required Fb10ByteWriter writer}) : _writer = writer;

  bool get isBusy => _isWriting || _queue.isNotEmpty;

  Future<void> enqueue(List<int> bytes) {
    if (_isClosed) {
      return Future<void>.value();
    }

    final completer = Completer<void>();
    _queue.add(_QueuedWrite(List<int>.unmodifiable(bytes), completer));
    _drain();
    return completer.future;
  }

  void close() {
    _isClosed = true;
    clearPending();
  }

  void clearPending() {
    while (_queue.isNotEmpty) {
      _queue.removeFirst().completer.complete();
    }
  }

  void _drain() {
    if (_isWriting || _queue.isEmpty) return;

    _isWriting = true;
    final item = _queue.removeFirst();

    Future<void>.sync(() => _writer(item.bytes))
        .then(
          (_) {
            item.completer.complete();
          },
          onError: (Object error, StackTrace stackTrace) {
            item.completer.completeError(error, stackTrace);
          },
        )
        .whenComplete(() {
          _isWriting = false;
          _drain();
        });
  }
}

class _QueuedWrite {
  final List<int> bytes;
  final Completer<void> completer;

  _QueuedWrite(this.bytes, this.completer);
}
