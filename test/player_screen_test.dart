import 'dart:io';
import 'dart:ui' as ui;
import 'package:duanju_app/local_store.dart';
import 'package:duanju_app/models.dart';
import 'package:duanju_app/player_screen.dart';
import 'package:duanju_app/app_layout.dart';
import 'package:duanju_app/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';
import 'player_fixtures.dart';

class PreloadingRouteRepository extends RouteRepository {
  final preloadedEpisodes = <int>[];

  @override
  Future<PlaybackPlan?> preload(
    Drama drama,
    Episode episode, {
    int quality = 0,
    bool online = false,
  }) async {
    preloadedEpisodes.add(episode.number);
    final session = 'preloaded-${episode.number}';
    active.add(session);
    return PlaybackPlan(
      url: 'https://media.test/$session.mp4',
      session: session,
      prefetchedBytes: 4 << 20,
    );
  }
}

void main() {
  setUp(mockPlayerDevice);
  var previewFontsLoaded = false;
  Future<void> capture(WidgetTester tester, String name) async {
    final directory = Platform.environment['HG_UI_CAPTURE_DIR'];
    if (directory == null) return;
    await tester.runAsync(() async {
      final image = await tester
          .renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('portrait-capture')),
          )
          .toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> settleOperations(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  Future<void> mount(
    WidgetTester tester,
    RouteRepository repository,
    ScriptedPlayer platform, {
    Size? size,
    FakeViewPadding? padding,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final font = Platform.environment['HG_UI_FONT'];
    if (font != null && !previewFontsLoaded) {
      await tester.runAsync(() async {
        for (final entry in {
          'UiPreviewCJK': font,
          'Roboto': font,
          'MaterialIcons': Platform.environment['HG_UI_ICON_FONT'],
        }.entries) {
          if (entry.value == null) continue;
          final data = await File(entry.value!).readAsBytes();
          await (FontLoader(
            entry.key,
          )..addFont(Future.value(ByteData.sublistView(data)))).load();
        }
      });
      previewFontsLoaded = true;
    }
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
    }
    if (padding != null) {
      tester.view.padding = padding;
    }
    final store = LocalStore(await SharedPreferences.getInstance());
    final detail = await repository.detail(FixtureRepository.free);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('portrait-capture'),
        child: MaterialApp(
          theme: font == null
              ? AppTheme.dark
              : AppTheme.dark.copyWith(
                  textTheme: AppTheme.dark.textTheme.apply(
                    fontFamily: 'UiPreviewCJK',
                  ),
                ),
          home: PlayerScreen(
            detail: detail,
            initialIndex: 0,
            initialPosition: 7,
            repository: repository,
            store: store,
            playerFactory: () => Player(platformPlayer: platform),
            videoBuilder: (controls) =>
                ColoredBox(color: const Color(0xFF17212A), child: controls),
          ),
        ),
      ),
    );
    await settleOperations(tester);
  }

  Future<void> unmount(WidgetTester tester, ScriptedPlayer player) async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetPadding();
    await settleOperations(tester);
    expect(player.disposed, isTrue);
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'fully buffered current episode immediately preloads and reuses the next session',
    (tester) async {
      final repository = PreloadingRouteRepository();
      final player = ScriptedPlayer();
      await mount(tester, repository, player, size: const Size(960, 540));
      expect(repository.preloadedEpisodes, isEmpty);
      expect(player.state.position, const Duration(seconds: 7));
      player.buffered(player.state.duration);
      await settleOperations(tester);
      expect(repository.preloadedEpisodes, [2]);
      expect(repository.primaryCalls, 1);
      player.buffered(player.state.duration);
      await settleOperations(tester);
      expect(repository.preloadedEpisodes, [2]);
      player.finishEpisode();
      await settleOperations(tester);
      expect(repository.primaryCalls, 1);
      expect(player.opened.last.uri, 'https://media.test/preloaded-2.mp4');
      expect(repository.active, {'preloaded-2'});
      await unmount(tester, player);
      expect(repository.active, isEmpty);
    },
  );

  testWidgets(
    'duplicate errors switch once while keeping progress, rate and pause state',
    (tester) async {
      final repository = RouteRepository();
      final player = ScriptedPlayer();
      await mount(tester, repository, player);
      await tester.tap(find.byKey(const ValueKey('player-speed')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1.5x').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('关闭菜单'));
      await tester.pumpAndSettle();
      await player.seek(const Duration(seconds: 28));
      await tester.pump();
      await tester.tap(find.byTooltip('暂停播放'));
      await settleOperations(tester);
      player.fail();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await settleOperations(tester);
      expect(repository.fallbackCalls, 1);
      expect(repository.primaryCalls, 1);
      expect(player.opened.last.start, const Duration(seconds: 28));
      expect(player.state.rate, 1.5);
      expect(player.played.last, isFalse);
      expect(repository.active.length, 1);
      expect(find.text('暂时无法播放'), findsNothing);
      await unmount(tester, player);
      expect(repository.active, isEmpty);
    },
  );

  testWidgets(
    'recovery exhaustion releases sessions and manual retry keeps the saved position',
    (tester) async {
      final repository = RouteRepository()..broken = true;
      final player = ScriptedPlayer();
      await mount(tester, repository, player);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
        await settleOperations(tester);
      }
      expect(repository.primaryCalls, 2);
      expect(repository.fallbackCalls, 2);
      expect(find.text('暂时无法播放'), findsOneWidget);
      expect(repository.active, isEmpty);
      await tester.pump(const Duration(seconds: 25));
      expect(repository.primaryCalls + repository.fallbackCalls, 4);
      repository.broken = false;
      await tester.tap(find.text('重试播放'));
      await settleOperations(tester);
      expect(player.opened.last.start, const Duration(seconds: 7));
      expect(find.text('暂时无法播放'), findsNothing);
      await unmount(tester, player);
      expect(repository.active, isEmpty);
    },
  );

  testWidgets(
    'switching episodes ignores a delayed fallback and frees both old plans',
    (tester) async {
      final repository = RouteRepository()..deferFallback = true;
      final player = ScriptedPlayer();
      await mount(tester, repository, player);
      player.fail();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await settleOperations(tester);
      expect(repository.pending, isNotNull);
      await tester.tap(find.byKey(const ValueKey('play-episode-2')));
      await settleOperations(tester);
      final currentURL = player.opened.last.uri;
      final late = PlaybackPlan(
        url: 'https://media.test/late.mp4',
        session: 'late',
      );
      repository.active.add(late.session);
      repository.pending!.complete(late);
      await settleOperations(tester);
      expect(player.opened.last.uri, currentURL);
      expect(repository.active.length, 1);
      expect(repository.active, isNot(contains('late')));
      await unmount(tester, player);
      expect(repository.active, isEmpty);
    },
  );

  testWidgets('picture-in-picture hides app overlay controls', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(AppDevice.channel, (call) async {
      switch (call.method) {
        case 'pictureInPictureStatus':
          return {'supported': true, 'active': false};
        case 'enterPictureInPicture':
          return {'supported': true, 'active': true, 'requested': true};
      }
      return null;
    });
    try {
      final repository = RouteRepository();
      final player = ScriptedPlayer();
      await mount(tester, repository, player, size: const Size(390, 844));
      expect(
        find.byKey(const ValueKey('player-picture-in-picture')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('player-portrait-episodes')),
        findsOneWidget,
      );
      expect(find.text('简介'), findsOneWidget);
      expect(find.text('下载'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('player-picture-in-picture')));
      await tester.pump();
      await tester.pump();
      await settleOperations(tester);
      expect(
        find.byKey(const ValueKey('player-picture-in-picture')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('player-speed')), findsNothing);
      expect(find.byKey(const ValueKey('player-quality')), findsNothing);
      expect(find.byKey(const ValueKey('player-progress')), findsNothing);
      expect(
        find.byKey(const ValueKey('player-portrait-episodes')),
        findsNothing,
      );
      expect(find.text('简介'), findsNothing);
      expect(find.text('下载'), findsNothing);
      await unmount(tester, player);
    } finally {
      messenger.setMockMethodCallHandler(AppDevice.channel, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'fullscreen transport seeks and advances through existing playback logic',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final repository = RouteRepository();
        final player = ScriptedPlayer();
        await mount(tester, repository, player, size: const Size(960, 540));
        player.videoSize(1920, 1080);
        await settleOperations(tester);
        await tester.tap(find.byKey(const ValueKey('player-mobile-forward')));
        await settleOperations(tester);
        expect(player.state.position, const Duration(seconds: 22));
        expect(player.opened.length, 1);
        await tester.tap(find.byKey(const ValueKey('player-mobile-next')));
        await settleOperations(tester);
        expect(player.opened.length, 2);
        expect(find.text('第 2 集'), findsOneWidget);
        expect(player.state.position, Duration.zero);
        expect(player.state.playing, isTrue);
        await unmount(tester, player);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('mobile player pane starts below the system status area', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final repository = RouteRepository();
      final player = ScriptedPlayer();
      await mount(
        tester,
        repository,
        player,
        size: const Size(390, 844),
        padding: const FakeViewPadding(top: 32),
      );
      final surface = tester.getRect(
        find.byKey(const ValueKey('player-gesture-surface')),
      );
      expect(surface.top, greaterThanOrEqualTo(32));
      expect(surface.height, greaterThan(780));
      await unmount(tester, player);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPadding();
    }
  });

  testWidgets('compact player tools stay clustered instead of evenly spread', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(AppDevice.channel, (call) async {
      if (call.method == 'pictureInPictureStatus') {
        return {'supported': true, 'active': false};
      }
      return null;
    });
    try {
      final repository = RouteRepository();
      final player = ScriptedPlayer();
      await mount(tester, repository, player, size: const Size(390, 844));
      final speed = tester.getRect(find.byKey(const ValueKey('player-speed')));
      final quality = tester.getRect(
        find.byKey(const ValueKey('player-quality')),
      );
      final pip = tester.getRect(
        find.byKey(const ValueKey('player-picture-in-picture')),
      );
      expect(quality.left - speed.right, lessThan(8));
      expect(pip.left - quality.right, lessThan(8));
      expect(pip.right, greaterThan(330));
      await unmount(tester, player);
    } finally {
      messenger.setMockMethodCallHandler(AppDevice.channel, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });
  testWidgets(
    'portrait panels preserve video bounds and playback, switch tabs and close after selection',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final repository = RouteRepository();
        final player = ScriptedPlayer();
        await mount(tester, repository, player, size: const Size(390, 844));
        player.videoSize(720, 1280);
        await settleOperations(tester);
        final before = tester.getRect(
          find.byKey(const ValueKey('player-gesture-surface')),
        );
        expect(before.height, greaterThan(800));
        expect(find.byKey(const ValueKey('play-episode-2')), findsNothing);
        await capture(tester, 'portrait-watching');
        final opened = player.opened.length;
        await tester.tap(
          find.byKey(const ValueKey('player-portrait-episodes')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('play-episode-2')), findsOneWidget);
        expect(player.state.playing, isTrue);
        expect(player.opened.length, opened);
        await capture(tester, 'portrait-episodes');
        expect(
          tester.getRect(find.byKey(const ValueKey('player-gesture-surface'))),
          before,
        );
        await tester.tap(find.text('简介').last);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('player-follow-status')),
          findsOneWidget,
        );
        await tester.tap(find.text('下载').last);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('player-follow-status')),
          findsNothing,
        );
        await tester.tap(find.text('选集'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('play-episode-2')));
        await tester.pumpAndSettle();
        expect(find.byTooltip('收起面板'), findsNothing);
        expect(repository.requestedEpisodes.last, 2);
        expect(player.state.playing, isTrue);
        expect(
          tester.getRect(find.byKey(const ValueKey('player-gesture-surface'))),
          before,
        );
        await tester.tap(
          find.byKey(const ValueKey('player-portrait-details-1')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('player-follow-status')),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('收起面板'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('player-follow-status')),
          findsNothing,
        );
        await unmount(tester, player);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
