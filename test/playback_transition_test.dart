import 'dart:async';

import 'package:duanju_app/luna_exo_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:duanju_app/models.dart';
import 'package:duanju_app/local_store.dart';
import 'package:duanju_app/player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'luna_exo_diagnostics_test.dart' show DiagnosticVideoPlatform;

class TransitionRepository extends FixtureRepository {
  final active = <String>{};
  @override
  Future<PlaybackPlan> resolve(
    Drama drama,
    Episode episode, {
    int quality = 0,
  }) async {
    final session = 'episode-${episode.number}';
    active.add(session);
    return PlaybackPlan(
      url: 'file:///synthetic-$session.mp4',
      session: session,
    );
  }

  @override
  Future<void> release(String session) async {
    active.remove(session);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiagnosticVideoPlatform platform;
  late VideoPlayerPlatform previous;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const response = {
    'durationMs': 90000,
    'width': 1280,
    'height': 720,
    'elapsedMs': 120,
  };
  setUp(() {
    previous = VideoPlayerPlatform.instance;
    platform = DiagnosticVideoPlatform();
    VideoPlayerPlatform.instance = platform;
  });
  tearDown(() {
    VideoPlayerPlatform.instance = previous;
    messenger.setMockMethodCallHandler(LunaExoPlayer.diagnosticChannel, null);
  });
  testWidgets(
    'automatic next episode keeps the view and omits the full screen loading curtain',
    (tester) async {
      final repository = TransitionRepository();
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());
      final player = LunaExoPlayer();
      final pending = Completer<Map<String, Object>>();
      var transitions = 0;
      messenger.setMockMethodCallHandler(LunaExoPlayer.diagnosticChannel, (
        call,
      ) {
        if (call.method != 'transition') return Future.value({});
        transitions++;
        return pending.future;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            detail: await repository.detail(FixtureRepository.free),
            initialIndex: 0,
            repository: repository,
            store: store,
            playerFactory: () => player,
            videoBuilder: (controls) =>
                ColoredBox(color: Colors.blueGrey, child: controls),
          ),
        ),
      );
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(player.controller, isNotNull);
      final controller = player.controller!;
      controller.value = controller.value.copyWith(
        position: controller.value.duration,
      );
      platform.streams[0]!.add(VideoEvent(eventType: VideoEventType.completed));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(transitions, 1);
      expect(platform.created, 1);
      expect(platform.disposed, isEmpty);
      expect(player.controller, same(controller));
      expect(find.text('正在准备播放'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(repository.active, {'episode-1', 'episode-2'});
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('正在衔接下一集…'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('正在衔接下一集…'), findsOneWidget);
      pending.complete(response);
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.text('正在衔接下一集…'), findsNothing);
      expect(player.state.playing, true);
      expect(repository.active, {'episode-2'});
      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump();
      expect(repository.active, isEmpty);
      expect(player.controller, isNull);
      expect(platform.disposed, [0]);
      store.dispose();
    },
  );
  testWidgets(
    'failed handoff and failed fresh load leave loading and offer retry',
    (tester) async {
      final repository = TransitionRepository();
      SharedPreferences.setMockInitialValues({});
      final store = LocalStore(await SharedPreferences.getInstance());
      final player = LunaExoPlayer(
        initializationTimeout: const Duration(milliseconds: 30),
        transitionTimeout: const Duration(milliseconds: 30),
      );
      final pending = Completer<Map<String, Object>>();
      messenger.setMockMethodCallHandler(LunaExoPlayer.diagnosticChannel, (
        call,
      ) {
        return call.method == 'transition' ? pending.future : Future.value({});
      });
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(
            detail: await repository.detail(FixtureRepository.free),
            initialIndex: 0,
            repository: repository,
            store: store,
            playerFactory: () => player,
            videoBuilder: (controls) =>
                ColoredBox(color: Colors.blueGrey, child: controls),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      final controller = player.controller!;
      controller.value = controller.value.copyWith(
        position: controller.value.duration,
      );
      platform.initialize = false;
      platform.streams[0]!.add(VideoEvent(eventType: VideoEventType.completed));
      for (var i = 0; i < 1200; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(find.text('正在衔接下一集…'), findsNothing);
      expect(find.text('暂时无法播放'), findsOneWidget);
      expect(find.text('重试播放'), findsOneWidget);
      expect(platform.created, 3);
      pending.complete(response);
      await tester.pump();
      expect(player.controller, isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      expect(repository.active, isEmpty);
      store.dispose();
    },
  );

  test(
    'twenty automatic transitions retain one initialized controller and reset each episode',
    () async {
      final ids = <int>[];
      messenger.setMockMethodCallHandler(LunaExoPlayer.diagnosticChannel, (
        call,
      ) async {
        if (call.method != 'transition') return {};
        ids.add((call.arguments as Map)['playerId'] as int);
        expect(
          (call.arguments as Map)['headers']['Referer'],
          'https://synthetic.test',
        );
        return response;
      });
      final player = LunaExoPlayer();
      addTearDown(player.dispose);
      await player.open(Media('file:///synthetic-1.mp4'));
      final controller = player.controller;
      for (var episode = 2; episode <= 21; episode++) {
        await player.transitionTo(
          Media(
            'file:///synthetic-$episode.mp4',
            httpHeaders: {'Referer': 'https://synthetic.test'},
          ),
        );
        expect(player.controller, same(controller));
        expect(player.state.duration, const Duration(seconds: 90));
        expect(player.state.position, Duration.zero);
        expect(player.state.completed, false);
        expect(player.state.playing, true);
      }
      expect(ids, List.filled(20, 0));
      expect(platform.created, 1);
      expect(platform.disposed, isEmpty);
      expect(platform.peakLive, 1);
    },
  );
  test(
    'first frame wait keeps old view attached and background pause survives completion',
    () async {
      final pending = Completer<Map<String, Object>>();
      final started = Completer<void>();
      messenger.setMockMethodCallHandler(LunaExoPlayer.diagnosticChannel, (
        call,
      ) {
        if (call.method != 'transition') return Future.value({});
        started.complete();
        return pending.future;
      });
      final player = LunaExoPlayer();
      addTearDown(player.dispose);
      await player.open(Media('file:///synthetic-1.mp4'));
      final controller = player.controller;
      final changing = player.transitionTo(Media('file:///synthetic-2.mp4'));
      await started.future;
      expect(player.controller, same(controller));
      expect(controller!.value.isInitialized, true);
      expect(platform.disposed, isEmpty);
      await player.pause();
      pending.complete(response);
      await changing;
      expect(player.state.playing, false);
      expect(player.controller, same(controller));
    },
  );
  test(
    'failed transition falls back with old controller released before recreation',
    () async {
      messenger.setMockMethodCallHandler(LunaExoPlayer.diagnosticChannel, (
        call,
      ) async {
        if (call.method == 'transition')
          throw PlatformException(code: 'transition_failed');
        return {};
      });
      final player = LunaExoPlayer();
      addTearDown(player.dispose);
      await player.open(Media('file:///synthetic-1.mp4'));
      await player.transitionTo(Media('file:///synthetic-2.mp4'));
      expect(platform.created, 2);
      expect(platform.disposed, [0]);
      expect(platform.peakLive, 1);
      expect(player.state.playing, true);
    },
  );
  test(
    'missing native reply has a deadline and late reply cannot reset the replacement',
    () async {
      final pending = Completer<Map<String, Object>>();
      messenger.setMockMethodCallHandler(LunaExoPlayer.diagnosticChannel, (
        call,
      ) {
        return call.method == 'transition' ? pending.future : Future.value({});
      });
      final player = LunaExoPlayer(
        transitionTimeout: const Duration(milliseconds: 30),
      );
      addTearDown(player.dispose);
      await player.open(Media('file:///synthetic-1.mp4'));
      await player.transitionTo(Media('file:///synthetic-2.mp4'));
      final current = player.controller;
      expect(platform.created, 2);
      expect(platform.disposed, [0]);
      expect(player.state.playing, true);
      pending.complete(response);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(player.controller, same(current));
      expect(platform.created, 2);
    },
  );

  test(
    'failed preloaded transition requests fresh resolution without reopening the same URL',
    () async {
      messenger.setMockMethodCallHandler(LunaExoPlayer.diagnosticChannel, (
        call,
      ) async {
        if (call.method == 'transition')
          throw PlatformException(code: 'transition_timeout');
        return {};
      });
      final player = LunaExoPlayer();
      addTearDown(player.dispose);
      await player.open(Media('file:///synthetic-1.mp4'));
      await expectLater(
        player.transitionTo(
          Media('file:///expired-cache.mp4'),
          reopenOnFailure: false,
        ),
        throwsA(isA<PlatformException>()),
      );
      expect(platform.created, 1);
      expect(player.canTransition, true);
    },
  );

  test(
    'leaving during first frame wait does not resurrect the disposed controller',
    () async {
      final pending = Completer<Map<String, Object>>();
      final started = Completer<void>();
      messenger.setMockMethodCallHandler(LunaExoPlayer.diagnosticChannel, (
        call,
      ) {
        if (call.method != 'transition') return Future.value({});
        started.complete();
        return pending.future;
      });
      final player = LunaExoPlayer();
      await player.open(Media('file:///synthetic-1.mp4'));
      final changing = player.transitionTo(Media('file:///synthetic-2.mp4'));
      await started.future;
      await player.dispose();
      pending.complete(response);
      await changing;
      expect(platform.created, 1);
      expect(platform.disposed, [0]);
      expect(player.controller, isNull);
    },
  );
}
