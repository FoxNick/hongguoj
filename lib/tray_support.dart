import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'app_build.dart';
import 'diary_service.dart';

const trayIconAsset = 'windows/runner/resources/app_icon.ico';

class _TrayIconListener with TrayListener {
  @override
  void onTrayIconMouseDown() => unawaited(showMainWindow());

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'exit') {
      unawaited(exitApplication());
    } else if (menuItem.key == 'show') {
      unawaited(showMainWindow());
    }
  }
}

class _TrayWindowListener with WindowListener {
  @override
  void onWindowClose() async {
    if (!await windowManager.isPreventClose()) return;
    await windowManager.hide();
  }
}

final _trayListener = _TrayIconListener();
final _windowListener = _TrayWindowListener();

Future<void> showMainWindow() async {
  await windowManager.show();
  await windowManager.focus();
}

Future<void> exitApplication() async {
  await windowManager.setPreventClose(false);
  await trayManager.destroy();
  await windowManager.destroy();
}

Future<void> initializeTray() async {
  if (!Platform.isWindows) return;
  try {
    await trayManager.setIcon(trayIconAsset);
    await trayManager.setToolTip(appName);
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'show', label: '显示主界面'),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: '退出'),
        ],
      ),
    );
    trayManager.addListener(_trayListener);
    windowManager.addListener(_windowListener);
    await windowManager.setPreventClose(true);
  } catch (error) {
    DiaryService.add('[托盘] 初始化失败：$error');
  }
}
