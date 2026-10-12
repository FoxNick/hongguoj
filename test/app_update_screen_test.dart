import 'dart:async';
import 'dart:io';

import 'package:duanju_app/app_layout.dart';
import 'package:duanju_app/app_update_screen.dart';
import 'package:duanju_app/app_updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_updates_test.dart'
    show FakeUpdateTransport, FakeUpdatePlatform, installed, releaseJson;

void main() {
  late AppUpdates updater;
  late FakeUpdatePlatform platform;
  late FakeUpdateTransport transport;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    platform = FakeUpdatePlatform(Directory.systemTemp.path);
    transport = FakeUpdateTransport();
    updater = AppUpdates(
      supportedEdition: true,
      preferences: await SharedPreferences.getInstance(),
      transport: transport,
      platform: platform,
    );
    updater.installedApp = installed;
    updater.release = AppRelease.parse(releaseJson(), installed);
    updater.stage = UpdateStage.available;
  });
  tearDown(() {
    updater.dispose();
    AppUpdates.current = null;
  });

  testWidgets('phone shows version notes and download without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: AppUpdateScreen(updates: updater)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('0.1.5'), findsOneWidget);
    expect(find.text('修复与安全更新'), findsOneWidget);
    expect(find.byKey(const ValueKey('download-app-update')), findsOneWidget);
    expect(find.byKey(const ValueKey('install-app-update')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'TV remote focus reaches permission controls; back stays cancellable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(960, 540));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      updater.stage = UpdateStage.permission;
      await tester.pumpWidget(
        MaterialApp(
          theme: televisionTheme(ThemeData()),
          home: AppLayout(
            television: true,
            child: AppUpdateScreen(updates: updater),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(platform.permissions, 1);
      expect(platform.installs, 0);
      expect(updater.stage, UpdateStage.permission);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(updater.stage, UpdateStage.ready);
      expect(find.byKey(const ValueKey('install-app-update')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'leaving update page during lookup never reopens it or interrupts underlying route',
    (tester) async {
      AppUpdates.current = updater;
      updater.release = null;
      updater.stage = UpdateStage.idle;
      transport.lookup = Completer<Map<String, dynamic>>();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  const Text('播放页面保持原位'),
                  TextButton(
                    onPressed: () => openAppUpdates(context),
                    child: const Text('打开更新'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开更新'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('check-app-update')));
      await tester.pump();
      navigator.currentState!.pop();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.runAsync(() async {
        transport.lookup!.complete(releaseJson());
        for (var i = 0; i < 20 && updater.stage == UpdateStage.checking; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('播放页面保持原位'), findsOneWidget);
      expect(find.byType(AppUpdateScreen), findsNothing);
      expect(platform.installs, 0);
      expect(transport.downloads, 0);
    },
  );
  testWidgets(
    'installer cancellation returns to ready without claiming success',
    (tester) async {
      updater.stage = UpdateStage.ready;
      platform.allowed = true;
      await tester.pumpWidget(
        MaterialApp(home: AppUpdateScreen(updates: updater)),
      );
      await tester.tap(find.byKey(const ValueKey('install-app-update')));
      await tester.pumpAndSettle();
      expect(platform.installs, 1);
      expect(find.textContaining('安装已取消'), findsOneWidget);
      expect(find.byKey(const ValueKey('install-app-update')), findsOneWidget);
      expect(find.text('更新已安装'), findsNothing);
    },
  );
}
