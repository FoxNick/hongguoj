import 'dart:async';

import 'package:duanju_app/app_theme.dart';
import 'package:duanju_app/local_store.dart';
import 'package:duanju_app/player_controls.dart';
import 'package:duanju_app/player_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';
import 'player_fixtures.dart';

void main() {
  setUp(mockPlayerDevice);

  Future<void> settle(WidgetTester tester) async {
    for (var index = 0; index < 24; index++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> gesture(WidgetTester tester, {bool cancel = false}) async {
    for (final call in [
      const MethodCall('startBackGesture', {
        'touchOffset': [0.0, 250.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      const MethodCall('updateBackGestureProgress', {
        'touchOffset': [50.0, 250.0],
        'progress': 0.5,
        'swipeEdge': 0,
      }),
      MethodCall(cancel ? 'cancelBackGesture' : 'commitBackGesture'),
    ]) {
      final reply = Completer<void>();
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        const StandardMethodCodec().encodeMethodCall(call),
        (_) => reply.complete(),
      );
      await tester.pump();
      await reply.future;
    }
    await settle(tester);
  }

  for (final fullscreen in [false, true]) {
    for (final predictive in [false, true]) {
      testWidgets(
        'phone back preserves stack fullscreen=$fullscreen predictive=$predictive',
        (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          tester.view.physicalSize = fullscreen
              ? const Size(960, 540)
              : const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          SharedPreferences.setMockInitialValues({});
          final store = LocalStore(await SharedPreferences.getInstance());
          final repository = RouteRepository();
          final platform = ScriptedPlayer();
          final detail = await repository.detail(FixtureRepository.free);
          try {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.dark,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlayerScreen(
                            detail: detail,
                            initialIndex: 0,
                            repository: repository,
                            store: store,
                            playerFactory: () =>
                                Player(platformPlayer: platform),
                            videoBuilder: (controls) => controls,
                          ),
                        ),
                      ),
                      child: const Text('打开合成视频'),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('打开合成视频'));
            await settle(tester);
            platform.videoSize(1920, 1080);
            await settle(tester);
            expect(
              tester
                  .widget<PlayerControls>(find.byType(PlayerControls))
                  .fullscreen,
              fullscreen,
            );
            if (predictive) {
              await gesture(tester, cancel: true);
              expect(find.byType(PlayerScreen), findsOneWidget);
              expect(platform.state.playing, isTrue);
              expect(
                tester
                    .widget<PlayerControls>(find.byType(PlayerControls))
                    .fullscreen,
                fullscreen,
              );
            }
            Future<void> back() async {
              if (predictive) {
                await gesture(tester);
              } else {
                await tester.binding.handlePopRoute();
                await settle(tester);
              }
            }

            if (fullscreen) {
              await back();
              expect(find.byType(PlayerScreen), findsOneWidget);
              expect(
                tester
                    .widget<PlayerControls>(find.byType(PlayerControls))
                    .fullscreen,
                isFalse,
              );
              expect(platform.disposed, isFalse);
              expect(platform.state.playing, isTrue);
            }
            await back();
            expect(find.byType(PlayerScreen), findsNothing);
            expect(find.text('打开合成视频'), findsOneWidget);
            expect(platform.disposed, isTrue);
            expect(repository.active, isEmpty);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await settle(tester);
            store.dispose();
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );
    }
  }
}
