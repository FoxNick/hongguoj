import 'package:duanju_app/app_layout.dart';
import 'package:duanju_app/storage_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BuildContext> contextOf(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return context;
  }

  void mockPermission(
    WidgetTester tester,
    bool allowed,
    List<String> methods,
  ) {
    final messaging =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messaging.setMockMethodCallHandler(AppDevice.channel, (call) async {
      methods.add(call.method);
      if (call.method == 'storagePermission') return allowed;
      return null;
    });
    addTearDown(
      () => messaging.setMockMethodCallHandler(AppDevice.channel, null),
    );
  }

  testWidgets('granted access allows downloads without a dialog', (
    tester,
  ) async {
    final methods = <String>[];
    mockPermission(tester, true, methods);
    final context = await contextOf(tester);
    expect(await StorageAccess.granted(), isTrue);
    expect(await StorageAccess.ensure(context), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('需要存储权限'), findsNothing);
  });

  testWidgets('denied access explains the target folder and opens settings', (
    tester,
  ) async {
    final methods = <String>[];
    mockPermission(tester, false, methods);
    final context = await contextOf(tester);
    final pending = StorageAccess.ensure(context);
    await tester.pumpAndSettle();
    expect(find.text('需要存储权限'), findsOneWidget);
    expect(find.textContaining('短句汇'), findsOneWidget);
    await tester.tap(find.text('去授权'));
    await tester.pumpAndSettle();
    expect(await pending, isFalse);
    expect(methods, contains('requestStoragePermission'));
  });

  testWidgets('cancel keeps downloads blocked without opening settings', (
    tester,
  ) async {
    final methods = <String>[];
    mockPermission(tester, false, methods);
    final context = await contextOf(tester);
    final pending = StorageAccess.ensure(context);
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await pending, isFalse);
    expect(methods, isNot(contains('requestStoragePermission')));
  });
}
