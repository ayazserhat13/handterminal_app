import 'dart:developer' as developer;

import 'fb10_display_decoder.dart';
import 'fb10_display_frame.dart';

class Fb10FrameParser {
  final Fb10DisplayDecoder _decoder;
  final bool _debugLogging;
  final List<int> _buffer = <int>[];

  Fb10FrameParser({
    Fb10DisplayDecoder decoder = const Fb10DisplayDecoder(),
    bool debugLogging = false,
  }) : _decoder = decoder,
       _debugLogging = debugLogging;

  int get bufferedByteCount => _buffer.length;

  void clear() {
    _buffer.clear();
  }

  List<Fb10DisplayFrame> addBytes(List<int> bytes) {
    if (bytes.isEmpty) return const <Fb10DisplayFrame>[];

    for (final byte in bytes) {
      if (_isProtocolControlByte(byte)) {
        _debugLog('dropped control byte ${_formatByte(byte)}');
        continue;
      }

      _buffer.add(byte);
    }

    _debugLog('buffer length ${_buffer.length}');

    return _consumeFrames();
  }

  List<Fb10DisplayFrame> _consumeFrames() {
    final frames = <Fb10DisplayFrame>[];

    while (_buffer.length >= Fb10DisplayFrame.frameByteCount) {
      final frame = _buffer.sublist(0, Fb10DisplayFrame.frameByteCount);
      _buffer.removeRange(0, Fb10DisplayFrame.frameByteCount);

      _debugFrame(frame);

      final parsedFrame = _parseFrame(frame);
      if (parsedFrame != null) {
        _debugLog('emitted frame length ${frame.length}');
        frames.add(parsedFrame);
      }

      _debugLog('buffer length ${_buffer.length}');
    }

    return frames;
  }

  Fb10DisplayFrame? _parseFrame(List<int> data) {
    if (data.length != Fb10DisplayFrame.frameByteCount) return null;

    final status = data[Fb10DisplayFrame.displayByteCount];

    if (!_isStatusByte(status)) {
      return null;
    }

    return Fb10DisplayFrame(
      lines: _decoder.decodeLines(
        data.sublist(0, Fb10DisplayFrame.displayByteCount),
      ),
      status: status,
    );
  }

  bool looksLikeValidFrame(List<int> frame) {
    if (frame.length != Fb10DisplayFrame.frameByteCount) return false;

    final status = frame[Fb10DisplayFrame.displayByteCount];

    if (!_isStatusByte(status)) return false;

    final printableCount = frame
        .sublist(0, Fb10DisplayFrame.displayByteCount)
        .where(_isPrintableOrExtended)
        .length;

    if (printableCount < 52) return false;

    final controlCount = frame
        .sublist(0, Fb10DisplayFrame.displayByteCount)
        .where(_isUnexpectedControlByte)
        .length;

    if (controlCount > 4) return false;

    return true;
  }

  bool _isStatusByte(int byte) {
    return (byte & 0xF0) == 0x50;
  }

  bool _isProtocolControlByte(int byte) {
    return byte == 0xBB || byte == 0xAA || byte == 0xAF;
  }

  bool _isPrintableOrExtended(int byte) {
    return (byte >= 32 && byte <= 126) || byte >= 128;
  }

  bool _isUnexpectedControlByte(int byte) {
    return byte < 32 && byte != 0 && byte != 1 && byte != 2;
  }

  String _formatByte(int byte) {
    return '0x${byte.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  String _formatFrame(List<int> frame) {
    return frame.map(_formatByte).join(' ');
  }

  void _debugFrame(List<int> frame) {
    _debugLog(
      'frame hex ${_formatFrame(frame)} '
      'first byte ${_formatByte(frame.first)} '
      'last byte ${_formatByte(frame.last)} '
      'length ${frame.length}',
    );
  }

  void _debugLog(String message) {
    if (!_debugLogging) return;

    developer.log(message, name: 'Fb10FrameParser');
  }
}
