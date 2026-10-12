import 'dart:async';

import 'package:duanju_app/danmaku_emoji_assets.dart';
import 'package:duanju_app/danmaku_emoji_render.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class HoldingEmojiBundle extends CachingAssetBundle {
  final pending = Completer<ByteData>();
  int calls = 0;
  @override
  Future<ByteData> load(String key) {
    calls++;
    return pending.future;
  }
}

class FailingEmojiBundle extends CachingAssetBundle {
  int calls = 0;
  @override
  Future<ByteData> load(String key) async {
    calls++;
    throw StateError('Synthetic unavailable asset');
  }
}

Future<void> finishDecoding(
  WidgetTester tester,
  DanmakuEmojiCache cache,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (cache.loading && DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(cache.loading, isFalse);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const style = TextStyle(fontSize: 14, color: Colors.white);
  const scaler = TextScaler.noScaling;

  test(
    'only supported graphemes become images and ordinary text stays intact',
    () {
      final content = DanmakuEmojiContent.parse(
        '爽 怒 撇嘴 [未知] 😆😠😒 👩🏽‍💻 ♥ 3',
      );
      expect(content.parts.where((part) => part.asset != null), hasLength(3));
      expect(
        content.parts.map((part) => part.text).join(),
        '爽 怒 撇嘴 [未知] 😆😠😒 👩🏽‍💻 ♥ 3',
      );
      expect(DanmakuEmojiContent.parse('普通[未知]文字').hasImages, isFalse);
      expect(DanmakuEmojiContent.parse('👩🏽‍💻').parts.single.text, '👩🏽‍💻');
    },
  );

  testWidgets(
    'all image decodes are bounded to 64px and the 144-asset inventory',
    (tester) async {
      final cache = DanmakuEmojiCache();
      addTearDown(cache.dispose);
      final text = DanmakuEmojiAssets.paths.keys.join();
      cache.ensureLoaded([text, text, '[未知]']);
      await finishDecoding(tester, cache);
      expect(cache.imageCount, 144);
      expect(cache.decodedBytes, lessThanOrEqualTo(144 * 64 * 64 * 4));
      for (final glyph in DanmakuEmojiAssets.paths.keys) {
        final image = cache.imageFor(glyph)!;
        expect(image.width, lessThanOrEqualTo(64));
        expect(image.height, lessThanOrEqualTo(64));
      }
      cache.ensureLoaded([text]);
      expect(cache.loading, isFalse);
      expect(cache.imageCount, 144);
    },
  );

  testWidgets(
    'first frame has a visible text fallback, then bundled inline images with stable width',
    (tester) async {
      final bundle = HoldingEmojiBundle();
      final cache = DanmakuEmojiCache(bundle: bundle);
      addTearDown(cache.dispose);
      const text = '爽文 😆😠😒 [未知] ♥ 3';
      cache.ensureLoaded([text]);
      final before = DanmakuEmojiContent.parse(text).measure(style, scaler);
      Widget render() => MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedBuilder(
              animation: cache,
              builder: (context, _) => DanmakuEmojiText(
                text: text,
                style: style,
                scaler: scaler,
                cache: cache,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(render());
      expect(find.text('😆'), findsOneWidget);
      expect(find.text('😠'), findsOneWidget);
      expect(find.text('😒'), findsOneWidget);
      expect(find.byType(RawImage), findsNothing);
      await tester.runAsync(() async {
        bundle.pending.complete(
          await rootBundle.load('${DanmakuEmojiAssets.directory}1f606.png'),
        );
      });
      await finishDecoding(tester, cache);
      await tester.pump();
      expect(find.byType(RawImage), findsNWidgets(3));
      expect(DanmakuEmojiContent.parse(text).measure(style, scaler), before);
      expect(
        tester.getSize(find.byType(DanmakuEmojiText)).width,
        closeTo(before, .1),
      );
      final richText = tester.widget<Text>(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.semanticsLabel == text,
        ),
      );
      expect(richText.textSpan!.toPlainText(), contains('[未知] ♥ 3'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'missing or corrupt assets keep fallback text without repeated loads',
    (tester) async {
      final bundle = FailingEmojiBundle();
      final cache = DanmakuEmojiCache(bundle: bundle);
      addTearDown(cache.dispose);
      cache.ensureLoaded(['😆😆😆']);
      await finishDecoding(tester, cache);
      cache.ensureLoaded(['😆']);
      expect(bundle.calls, 1);
      expect(cache.imageCount, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanmakuEmojiText(
              text: '😆 [未知] 爽',
              style: style,
              scaler: scaler,
              cache: cache,
            ),
          ),
        ),
      );
      expect(find.text('😆'), findsOneWidget);
      expect(find.byType(RawImage), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'decode concurrency is bounded and disposal ignores late asset responses',
    (tester) async {
      final bundle = HoldingEmojiBundle();
      final cache = DanmakuEmojiCache(bundle: bundle);
      var notifications = 0;
      cache.addListener(() => notifications++);
      cache.ensureLoaded([DanmakuEmojiAssets.paths.keys.join()]);
      expect(bundle.calls, DanmakuEmojiCache.maxConcurrentDecodes);
      cache.dispose();
      await tester.runAsync(() async {
        bundle.pending.complete(
          await rootBundle.load('${DanmakuEmojiAssets.directory}1f606.png'),
        );
      });
      await finishDecoding(tester, cache);
      expect(cache.imageCount, 0);
      expect(cache.decodedBytes, 0);
      expect(notifications, 0);
      cache.ensureLoaded(['😆']);
      expect(bundle.calls, DanmakuEmojiCache.maxConcurrentDecodes);
    },
  );
}
