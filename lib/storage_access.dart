import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StorageAccess {
  const StorageAccess._();

  static const channel = MethodChannel('duanju/device');

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> granted() async {
    if (!_android) return true;
    try {
      return await channel.invokeMethod<bool>('storagePermission') ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<String> targetDirectory() async {
    if (!_android) return '';
    try {
      final value = await channel.invokeMethod<String>('downloadDirectory');
      return value ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> request() async {
    if (!_android) return;
    try {
      await channel.invokeMethod('requestStoragePermission');
    } catch (_) {}
  }

  static Future<bool> ensure(BuildContext context) async {
    if (await granted()) return true;
    if (!context.mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('需要存储权限'),
        content: const Text(
          '下载文件保存在系统「下载」目录下的「橙龙短剧」文件夹，需要开启「所有文件访问」权限。'
          '授权后返回应用即可继续下载。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialog).pop();
              request();
            },
            child: const Text('去授权'),
          ),
        ],
      ),
    );
    return false;
  }
}
