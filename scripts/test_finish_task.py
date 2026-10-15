import tempfile
import unittest
from pathlib import Path

from finish_task import finish_task
from sync_source import REQUIRED_FILES


class TaskSnapshotTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='duanju-snapshot-test-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / '源码'
        for name in REQUIRED_FILES:
            self.write(self.source / name, name)

    def write(self, path, content):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding='utf-8')

    def test_snapshot_counts_source_without_creating_any_copy(self):
        self.write(self.source / 'lib/电视.dart', '电视界面')
        self.write(self.source / 'build/app.apk', 'compiled binary')
        self.write(self.source / 'android/key.properties', 'private settings')
        result = finish_task(self.source, '完成电视界面')
        self.assertEqual(result.files, len(REQUIRED_FILES) + 1)
        self.assertGreater(result.total_bytes, 0)
        self.assertEqual([path.name for path in self.root.iterdir()], ['源码'])

    def test_blank_message_is_rejected(self):
        with self.assertRaises(ValueError):
            finish_task(self.source, '   ')

    def test_missing_listed_file_is_reported(self):
        (self.source / 'pubspec.lock').unlink()
        with self.assertRaises(ValueError):
            finish_task(self.source, '缺少必需文件')


if __name__ == '__main__':
    unittest.main()
