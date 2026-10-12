import 'package:duanju_app/danmaku_controller.dart';
import 'package:duanju_app/danmaku_models.dart';
import 'package:duanju_app/danmaku_emoji_render.dart';
import 'package:duanju_app/danmaku_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'danmaku_fixtures.dart';
import 'danmaku_test.dart' show danmakuPlan, flushDanmaku, updateDanmaku;

void main() {
  for (final television in [false, true]) {
    for (final missingFont in [false, true]) {
      testWidgets(
        'mixed expressions render with television=$television and missingFont=$missingFont',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = television
              ? const Size(960, 540)
              : const Size(390, 844);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final repository = DanmakuFixtureRepository()
            ..response = (request) => DanmakuPage(
              episodeId: request.plan.danmakuId,
              startMs: 0,
              nextMs: 30000,
              items: const [
                DanmakuItem(
                  id: 'first',
                  text: '爽文怒[爽]【怒】［撇嘴］[戳手手][未知] 😎',
                  timeMs: 0,
                ),
                DanmakuItem(
                  id: 'alias',
                  text: '爽文怒😆😠😒👉👈[未知] 😎',
                  timeMs: 500,
                ),
              ],
            );
          final controller = DanmakuController(repository)
            ..setPlan(danmakuPlan);
          addTearDown(controller.dispose);
          updateDanmaku(controller);
          await flushDanmaku();
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                fontFamily: missingFont
                    ? 'UnavailableSyntheticEmojiFont'
                    : null,
              ),
              home: Scaffold(
                body: DanmakuOverlay(
                  controller: controller,
                  aspectRatio: 16 / 9,
                  television: television,
                ),
              ),
            ),
          );
          const rendered = '爽文怒😆😠😒👉👈[未知] 😎  ♥ 2';
          final line = find.byWidgetPredicate(
            (widget) => widget is DanmakuEmojiText && widget.text == rendered,
          );
          expect(line, findsOneWidget);
          expect(find.textContaining('[爽]'), findsNothing);
          expect(
            find.byKey(const ValueKey('danmaku-item-alias')),
            findsNothing,
          );
          final text = tester.widget<DanmakuEmojiText>(line);
          expect(text.style.fontSize, television ? 14 : 12);
          expect(text.style.fontWeight, FontWeight.w400);
          expect(text.style.color!.a, closeTo(television ? .55 : .62, .01));
          final positioned = tester.widget<Positioned>(
            find.byKey(const ValueKey('danmaku-item-first')),
          );
          expect(positioned.width, greaterThan(0));
          expect(positioned.width!.isFinite, isTrue);
          expect(controller.items.single.timeMs, 0);
          expect(controller.items.single.repeatCount, 2);
          final deadline = DateTime.now().add(const Duration(seconds: 15));
          while (text.cache.loading && DateTime.now().isBefore(deadline)) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.pump();
          }
          expect(text.cache.loading, isFalse);
          await tester.pump();
          expect(
            find.descendant(of: line, matching: find.byType(RawImage)),
            findsNWidgets(6),
          );
          await tester.pump(const Duration(milliseconds: 500));
          updateDanmaku(controller, playing: false);
          await tester.pump();
          final motion = find.byKey(const ValueKey('danmaku-motion-first'));
          final pausedX = tester
              .widget<Transform>(motion)
              .transform
              .storage[12];
          await tester.pump(const Duration(seconds: 1));
          expect(
            tester.widget<Transform>(motion).transform.storage[12],
            closeTo(pausedX, .01),
          );
          expect(line, findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
