import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

class PlaybackFrameHold extends ChangeNotifier {
  PlaybackFrameHold({
    Duration retentionTimeout = const Duration(seconds: 12),
    Duration captureTimeout = const Duration(milliseconds: 250),
  }) : assert(retentionTimeout >= Duration.zero),
       assert(retentionTimeout <= const Duration(seconds: 12)),
       assert(captureTimeout >= Duration.zero),
       assert(captureTimeout <= const Duration(milliseconds: 250)),
       _retentionTimeout = retentionTimeout,
       _captureTimeout = captureTimeout;

  static const _maximumBytes = 1024 * 1024;
  static const _maximumEdge = 960;
  static const _maximumPixels = _maximumEdge * _maximumEdge;

  final Duration _retentionTimeout;
  final Duration _captureTimeout;
  Timer? _retentionTimer;
  Timer? _captureTimer;
  Completer<bool>? _pending;
  ui.Image? _image;
  bool _active = false;
  bool _disposed = false;
  int _generation = 0;

  ui.Image? get image => _image;
  bool get active => _active;

  Future<bool> capture(Future<Uint8List?> Function() loader) {
    if (_disposed) return Future<bool>.value(false);
    _reset(notify: false);
    final generation = _generation;
    final elapsed = Stopwatch()..start();
    final pending = Completer<bool>();
    _pending = pending;
    _active = true;
    _retentionTimer = Timer(_retentionTimeout, () => _expire(generation));
    _captureTimer = Timer(_captureTimeout, () => _expire(generation));
    notifyListeners();
    if (_current(generation)) {
      unawaited(_loadAndDecode(loader, generation, elapsed));
    }
    return pending.future;
  }

  bool _current(int generation) =>
      !_disposed && _active && generation == _generation;

  bool _withinBudget(int generation, Stopwatch elapsed) =>
      _current(generation) &&
      elapsed.elapsed < _captureTimeout &&
      elapsed.elapsed < _retentionTimeout;

  bool _validDimensions(int width, int height) =>
      width > 0 &&
      height > 0 &&
      width <= _maximumEdge &&
      height <= _maximumEdge &&
      width * height <= _maximumPixels;

  Future<void> _loadAndDecode(
    Future<Uint8List?> Function() loader,
    int generation,
    Stopwatch elapsed,
  ) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? decoded;
    try {
      if (!_withinBudget(generation, elapsed)) return;
      final bytes = await loader();
      if (!_withinBudget(generation, elapsed) ||
          bytes == null ||
          bytes.isEmpty ||
          bytes.lengthInBytes > _maximumBytes) {
        return;
      }
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      if (!_withinBudget(generation, elapsed)) return;
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (!_withinBudget(generation, elapsed) ||
          !_validDimensions(descriptor.width, descriptor.height)) {
        return;
      }
      codec = await descriptor.instantiateCodec();
      if (!_withinBudget(generation, elapsed)) return;
      decoded = (await codec.getNextFrame()).image;
      if (!_withinBudget(generation, elapsed) ||
          !_validDimensions(decoded.width, decoded.height)) {
        return;
      }
      _image = decoded;
      decoded = null;
      _captureTimer?.cancel();
      _captureTimer = null;
      notifyListeners();
      if (_withinBudget(generation, elapsed)) {
        final pending = _pending;
        _pending = null;
        pending?.complete(true);
      }
    } catch (_) {
    } finally {
      decoded?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
      if (_current(generation) && _pending != null) {
        _reset(notify: true);
      }
    }
  }

  void _expire(int generation) {
    if (_current(generation)) _reset(notify: true);
  }

  void clear() {
    if (!_disposed) _reset(notify: true);
  }

  void _reset({required bool notify}) {
    _generation++;
    _retentionTimer?.cancel();
    _retentionTimer = null;
    _captureTimer?.cancel();
    _captureTimer = null;
    final pending = _pending;
    _pending = null;
    final image = _image;
    _image = null;
    final changed = _active;
    _active = false;
    image?.dispose();
    pending?.complete(false);
    if (notify && changed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _reset(notify: false);
    super.dispose();
  }
}
