import 'dart:async';
import 'package:duanju_app/app_layout.dart';
import 'package:duanju_app/episode_swipe_surface.dart';
import 'package:duanju_app/player_interactions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'player_fixtures.dart';

void main() {
  testWidgets(
    'portrait edges switch episodes with drag, commit and rebound; never change brightness or media volume',
    (tester) async {
      tester.view.physicalSize = const Size(390, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final methods = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(AppDevice.channel, (call) async {
        methods.add(call.method);
        return .5;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(AppDevice.channel, null),
      );
      final platform = ScriptedPlayer();
      final player = Player(platformPlayer: platform);
      await player.open(Media('https://synthetic.test/video.mp4'));
      final directions = <int>[];
      final pending = Completer<void>();
      final interactions = PlayerInteractions(
        player: player,
        available: () => true,
        baseSpeed: () => 1,
        onTogglePlayback: () {},
        onFullscreen: () {},
        onEpisode: (_) => '',
        onEpisodeSwipe: (direction) async {
          directions.add(direction);
          await pending.future;
        },
      );
      await tester.pump();
      await tester.pumpWidget(
        MaterialApp(
          home: EpisodeSwipeSurface(
            enabled: true,
            interactions: interactions,
            previousLabel: '第 1 集',
            nextLabel: '第 3 集',
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => interactions.pointerDown(
                e,
                swipeEnabled: true,
                fullscreen: false,
                width: 390,
                height: 600,
              ),
              onPointerMove: interactions.pointerMove,
              onPointerUp: interactions.pointerUp,
              onPointerCancel: interactions.pointerCancel,
              child: const ColoredBox(
                color: Colors.blueGrey,
                child: Center(child: Text('合成第 2 集')),
              ),
            ),
          ),
        ),
      );
      double offset() => tester
          .widget<Transform>(find.byKey(const ValueKey('episode-swipe-page')))
          .transform
          .storage[13];
      final short = await tester.startGesture(const Offset(20, 350));
      await short.moveBy(const Offset(0, -35));
      await tester.pump();
      expect(offset(), closeTo(-35, .1));
      await short.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(offset(), closeTo(0, .1));
      expect(directions, isEmpty);
      final swipe = await tester.startGesture(const Offset(375, 350));
      await swipe.moveBy(const Offset(0, -110));
      await tester.pump();
      expect(offset(), closeTo(-110, .1));
      expect(find.text('第 3 集'), findsOneWidget);
      await swipe.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110));
      expect(offset(), lessThan(-110));
      await tester.pump(const Duration(milliseconds: 120));
      expect(directions, [1]);
      expect(offset(), closeTo(-600, .1));
      pending.complete();
      await tester.pump();
      expect(interactions.episodeCommit, 0);
      await tester.pump();
      expect(offset(), closeTo(0, .1));
      expect(
        methods.where((m) => m == 'setBrightness' || m == 'setMediaVolume'),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      interactions.dispose();
      await player.dispose();
    },
  );

  testWidgets(
    'fullscreen volume reads and writes system media volume and displays the actual returned step',
    (tester) async {
      final writes = <double>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(AppDevice.channel, (call) async {
        if (call.method == 'getBrightness') return .5;
        if (call.method == 'getMediaVolume') return .3;
        if (call.method == 'setMediaVolume') {
          writes.add((call.arguments as Map)['volume'] as double);
          return .4;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(AppDevice.channel, null),
      );
      final platform = ScriptedPlayer();
      final player = Player(platformPlayer: platform);
      await player.open(Media('https://synthetic.test/video.mp4'));
      await player.setVolume(20);
      final interactions = PlayerInteractions(
        player: player,
        available: () => true,
        baseSpeed: () => 1,
        onTogglePlayback: () {},
        onFullscreen: () {},
        onEpisode: (_) => '',
      );
      await tester.pump();
      interactions.pointerDown(
        const PointerDownEvent(
          pointer: 1,
          position: Offset(330, 300),
          kind: PointerDeviceKind.touch,
          buttons: kPrimaryButton,
        ),
        swipeEnabled: true,
        fullscreen: true,
        width: 390,
        height: 600,
      );
      interactions.pointerMove(
        const PointerMoveEvent(pointer: 1, position: Offset(330, 250)),
      );
      await tester.pump();
      expect(writes.single, closeTo(.3 + 50 / 360, .001));
      expect(interactions.hudState.value, .4);
      expect(platform.state.volume, 100);
      interactions.pointerUp(
        const PointerUpEvent(pointer: 1, position: Offset(330, 250)),
      );
      interactions.dispose();
      await player.dispose();
    },
  );
}
