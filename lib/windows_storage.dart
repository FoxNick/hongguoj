import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const windowsDownloadFolderName = '橙龙短剧';

const legacyAppDataFolders = ['真果鉴', '红果鉴'];

Future<void> prepareWindowsStorage() async {
  if (!Platform.isWindows) return;
  final appData = Platform.environment['APPDATA'];
  if (appData == null || appData.isEmpty) return;
  final support = await getApplicationSupportDirectory();
  final downloadsRoot = await getDownloadsDirectory();
  final target = downloadsRoot == null
      ? null
      : Directory(path.join(downloadsRoot.path, windowsDownloadFolderName));
  final legacy = _legacyDirectory(appData);
  if (legacy != null && support.listSync().isEmpty) {
    final legacyDownloads = Directory(path.join(legacy.path, 'downloads'));
    _moveChildren(legacy, support, skip: {'downloads'});
    if (target != null && legacyDownloads.existsSync()) {
      target.createSync(recursive: true);
      _moveChildren(legacyDownloads, target);
    } else if (legacyDownloads.existsSync()) {
      _moveChildren(legacyDownloads, support);
    }
  }
  if (target == null) return;
  await _writeDownloadLocation(support, target);
}

Directory? _legacyDirectory(String appData) {
  for (final name in legacyAppDataFolders) {
    final candidate = Directory(path.join(appData, name, name));
    if (candidate.existsSync()) return candidate;
  }
  return null;
}

void _moveChildren(Directory source, Directory target, {Set<String> skip = const {}}) {
  for (final entry in source.listSync()) {
    final name = path.basename(entry.path);
    if (skip.contains(name)) continue;
    final destination = path.join(target.path, name);
    if (FileSystemEntity.typeSync(destination) != FileSystemEntityType.notFound) {
      continue;
    }
    try {
      entry.renameSync(destination);
    } catch (_) {}
  }
}

Future<void> _writeDownloadLocation(Directory support, Directory target) async {
  final file = File(path.join(support.path, 'download-location.json'));
  if (file.existsSync()) return;
  target.createSync(recursive: true);
  await file.writeAsString(jsonEncode({'directory': target.path}));
}
