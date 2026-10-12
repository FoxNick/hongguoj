import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:duanju_app/playback_frame_hold.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List frameBytes;

  setUpAll(() async {
    frameBytes = await _syntheticFrame(32, 18);
  });

  test('capture settles only after a decoded image is available', () async {
    final hold = PlaybackFrameHold();
    addTearDown(hold.dispose);
    final states = <(bool, bool)>[];
    hold.addListener(() => states.add((hold.active, hold.image != null)));
    final request = Completer<Uint8List?>();
    final capture = hold.capture(() => request.future);
    expect(hold.active, isTrue);
    expect(hold.image, isNull);
    expect(states, [(true, false)]);
    request.complete(frameBytes);
    expect(await capture, isTrue);
    final image = hold.image!;
    expect((image.width, image.height), (32, 18));
    expect(image.debugDisposed, isFalse);
    expect(states, [(true, false), (true, true)]);
    hold.clear();
    expect(hold.active, isFalse);
    expect(hold.image, isNull);
    expect(image.debugDisposed, isTrue);
    expect(states, [(true, false), (true, true), (false, false)]);
    hold.clear();
    expect(states, hasLength(3));
  });

  test('replacing a hold immediately disposes its old image', () async {
    final hold = PlaybackFrameHold();
    addTearDown(hold.dispose);
    expect(await hold.capture(() async => frameBytes), isTrue);
    final previous = hold.image!;
    final request = Completer<Uint8List?>();
    final capture = hold.capture(() => request.future);
    expect(previous.debugDisposed, isTrue);
    expect(hold.active, isTrue);
    expect(hold.image, isNull);
    request.complete(frameBytes);
    expect(await capture, isTrue);
    expect(hold.image, isNot(same(previous)));
  });

  test('clear settles a pending loader and ignores its late bytes', () async {
    final hold = PlaybackFrameHold();
    addTearDown(hold.dispose);
    final request = Completer<Uint8List?>();
    final capture = hold.capture(() => request.future);
    hold.clear();
    expect(await capture, isFalse);
    request.complete(frameBytes);
    await _flush();
    expect(hold.active, isFalse);
    expect(hold.image, isNull);
  });

  test('a start listener can cancel before the loader runs', () async {
    final hold = PlaybackFrameHold();
    addTearDown(hold.dispose);
    var called = false;
    hold.addListener(() {
      if (hold.active) hold.clear();
    });
    expect(
      await hold.capture(() async {
        called = true;
        return frameBytes;
      }),
      isFalse,
    );
    expect(called, isFalse);
    expect(hold.active, isFalse);
  });

  test('an old loader cannot replace or clear a newer image', () async {
    final hold = PlaybackFrameHold();
    addTearDown(hold.dispose);
    final request = Completer<Uint8List?>();
    final previous = hold.capture(() => request.future);
    final current = hold.capture(() async => frameBytes);
    expect(await previous, isFalse);
    expect(await current, isTrue);
    final image = hold.image;
    request.complete(frameBytes);
    await _flush();
    expect(hold.active, isTrue);
    expect(hold.image, same(image));
    expect(image!.debugDisposed, isFalse);
  });

  test('late loader errors are contained after disposal', () async {
    final hold = PlaybackFrameHold();
    final request = Completer<Uint8List?>();
    final capture = hold.capture(() => request.future);
    hold.dispose();
    hold.dispose();
    hold.clear();
    expect(await capture, isFalse);
    request.completeError(StateError('synthetic late failure'));
    await _flush();
    expect(hold.active, isFalse);
    expect(hold.image, isNull);
    var called = false;
    expect(
      await hold.capture(() async {
        called = true;
        return frameBytes;
      }),
      isFalse,
    );
    expect(called, isFalse);
  });

  test(
    'dispose releases a decoded image without notifying listeners',
    () async {
      final hold = PlaybackFrameHold();
      expect(await hold.capture(() async => frameBytes), isTrue);
      final image = hold.image!;
      var notifications = 0;
      hold.addListener(() => notifications++);
      hold.dispose();
      expect(image.debugDisposed, isTrue);
      expect(hold.image, isNull);
      expect(hold.active, isFalse);
      expect(notifications, 0);
    },
  );

  testWidgets('capture gives up after a total 250 milliseconds', (
    tester,
  ) async {
    final hold = PlaybackFrameHold();
    addTearDown(hold.dispose);
    final request = Completer<Uint8List?>();
    final capture = hold.capture(() => request.future);
    await tester.pump(const Duration(milliseconds: 249));
    expect(hold.active, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(await capture, isFalse);
    expect(hold.active, isFalse);
    request.complete(frameBytes);
    await tester.pump();
    expect(hold.image, isNull);
  });

  test('the retention deadline includes time spent capturing', () async {
    final hold = PlaybackFrameHold(
      retentionTimeout: const Duration(milliseconds: 220),
    );
    addTearDown(hold.dispose);
    final expired = Completer<void>();
    hold.addListener(() {
      if (!hold.active && !expired.isCompleted) expired.complete();
    });
    final elapsed = Stopwatch()..start();
    expect(
      await hold.capture(() async {
        await Future<void>.delayed(const Duration(milliseconds: 140));
        return frameBytes;
      }),
      isTrue,
    );
    final image = hold.image!;
    await expired.future.timeout(const Duration(seconds: 1));
    expect(elapsed.elapsedMilliseconds, lessThan(310));
    expect(hold.image, isNull);
    expect(image.debugDisposed, isTrue);
  });

  testWidgets('retention can cancel capture before its capture budget', (
    tester,
  ) async {
    final hold = PlaybackFrameHold(
      retentionTimeout: const Duration(milliseconds: 30),
    );
    addTearDown(hold.dispose);
    final request = Completer<Uint8List?>();
    final capture = hold.capture(() => request.future);
    await tester.pump(const Duration(milliseconds: 30));
    expect(await capture, isFalse);
    expect(hold.active, isFalse);
    request.complete(frameBytes);
    await tester.pump();
    expect(hold.image, isNull);
  });

  for (final entry in <String, Uint8List?>{
    'null': null,
    'empty': Uint8List(0),
    'invalid': Uint8List.fromList([1, 2, 3, 4]),
    'over one MiB': Uint8List(1024 * 1024 + 1),
  }.entries) {
    test('${entry.key} input clears the hold and permits retry', () async {
      final hold = PlaybackFrameHold();
      addTearDown(hold.dispose);
      final states = <bool>[];
      hold.addListener(() => states.add(hold.active));
      expect(await hold.capture(() async => entry.value), isFalse);
      expect(hold.active, isFalse);
      expect(hold.image, isNull);
      expect(states, [true, false]);
      expect(await hold.capture(() async => frameBytes), isTrue);
    });
  }

  for (final asynchronous in [false, true]) {
    test('loader errors are contained (async: $asynchronous)', () async {
      final hold = PlaybackFrameHold();
      addTearDown(hold.dispose);
      expect(
        await hold.capture(() {
          if (asynchronous) {
            return Future<Uint8List?>.error(StateError('synthetic failure'));
          }
          throw StateError('synthetic failure');
        }),
        isFalse,
      );
      expect(hold.active, isFalse);
      expect(hold.image, isNull);
    });
  }

  test(
    'image dimensions are rejected before allocating decoded pixels',
    () async {
      final images = <ui.Image>[];
      final tooWide = await _syntheticFrame(961, 1);
      final tooTall = await _syntheticFrame(1, 961);
      final tooManyPixels = await _syntheticFrame(961, 961);
      _trackImages(images.add);
      final hold = PlaybackFrameHold();
      addTearDown(hold.dispose);
      for (final bytes in [tooWide, tooTall, tooManyPixels]) {
        expect(bytes.length, lessThan(1024 * 1024));
        expect(await hold.capture(() async => bytes), isFalse);
        expect(hold.image, isNull);
      }
      expect(images, isEmpty);
    },
  );

  test('a 960 by 960 frame fits the exact dimension limit', () async {
    final bytes = await _syntheticFrame(960, 960);
    final hold = PlaybackFrameHold();
    addTearDown(hold.dispose);
    expect(await hold.capture(() async => bytes), isTrue);
    expect((hold.image!.width, hold.image!.height), (960, 960));
  });

  test('a decoded frame arriving after clear is disposed', () async {
    final hold = PlaybackFrameHold();
    addTearDown(hold.dispose);
    final images = <ui.Image>[];
    _trackImages((image) {
      images.add(image);
      hold.clear();
    });
    expect(await hold.capture(() async => frameBytes), isFalse);
    await _flush();
    expect(images, hasLength(1));
    expect(images.single.debugDisposed, isTrue);
    expect(hold.image, isNull);
    expect(hold.active, isFalse);
  });

  test('a decoded frame arriving after disposal is disposed', () async {
    final hold = PlaybackFrameHold();
    final images = <ui.Image>[];
    _trackImages((image) {
      images.add(image);
      hold.dispose();
    });
    expect(await hold.capture(() async => frameBytes), isFalse);
    await _flush();
    expect(images, hasLength(1));
    expect(images.single.debugDisposed, isTrue);
    expect(hold.image, isNull);
    expect(hold.active, isFalse);
  });

  test('stale decoded frames do not touch a newer capture', () async {
    final hold = PlaybackFrameHold();
    addTearDown(hold.dispose);
    final images = <ui.Image>[];
    Future<bool>? replacement;
    _trackImages((image) {
      images.add(image);
      if (images.length == 1) {
        replacement = hold.capture(() async => frameBytes);
      }
    });
    expect(await hold.capture(() async => frameBytes), isFalse);
    expect(await replacement, isTrue);
    expect(images, hasLength(2));
    expect(images.first.debugDisposed, isTrue);
    expect(images.last.debugDisposed, isFalse);
    expect(hold.image, same(images.last));
    expect(hold.active, isTrue);
  });

  test('clearing from a ready listener never reports a ready image', () async {
    final hold = PlaybackFrameHold();
    addTearDown(hold.dispose);
    final images = <ui.Image>[];
    _trackImages(images.add);
    hold.addListener(() {
      if (hold.image != null) hold.clear();
    });
    expect(await hold.capture(() async => frameBytes), isFalse);
    expect(hold.image, isNull);
    expect(images.single.debugDisposed, isTrue);
  });

  test('repeated captures release images without filling imageCache', () async {
    final hold = PlaybackFrameHold();
    final images = <ui.Image>[];
    _trackImages(images.add);
    final cache = PaintingBinding.instance.imageCache;
    final cacheSize = (
      cache.currentSize,
      cache.currentSizeBytes,
      cache.liveImageCount,
    );
    for (var i = 0; i < 12; i++) {
      expect(await hold.capture(() async => frameBytes), isTrue);
      if (i.isEven) hold.clear();
    }
    hold.dispose();
    expect(images, hasLength(12));
    expect(images.every((image) => image.debugDisposed), isTrue);
    expect((
      cache.currentSize,
      cache.currentSizeBytes,
      cache.liveImageCount,
    ), cacheSize);
  });
}

void _trackImages(void Function(ui.Image) onCreate) {
  final previous = ui.Image.onCreate;
  ui.Image.onCreate = (image) {
    previous?.call(image);
    onCreate(image);
  };
  addTearDown(() => ui.Image.onCreate = previous);
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

Future<Uint8List> _syntheticFrame(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xFF286D81), ui.BlendMode.src);
  final picture = recorder.endRecording();
  ui.Image? image;
  try {
    image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image?.dispose();
    picture.dispose();
  }
}
