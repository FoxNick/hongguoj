import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class ConfigureSigningTests(unittest.TestCase):
    def test_missing_signing_fails_closed_and_cleanup_removes_properties(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'scripts').mkdir()
            (root / 'android').mkdir()
            script = root / 'scripts/configure_signing.py'
            shutil.copyfile(Path(__file__).with_name('configure_signing.py'), script)
            environment = os.environ.copy()
            environment['RUNNER_TEMP'] = str(root)
            for name in ['ANDROID_KEYSTORE_BASE64', 'ANDROID_KEYSTORE_PASSWORD',
                         'ANDROID_KEY_ALIAS', 'ANDROID_KEY_PASSWORD']:
                environment.pop(name, None)
            result = subprocess.run([sys.executable, str(script)], env=environment,
                                    capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((root / 'android/key.properties').exists())
            (root / 'duanju-release.jks').write_bytes(b'synthetic')
            (root / 'android/key.properties').write_text('synthetic')
            subprocess.run([sys.executable, str(script), '--clean'],
                           env=environment, check=True, capture_output=True)
            self.assertFalse((root / 'duanju-release.jks').exists())
            self.assertFalse((root / 'android/key.properties').exists())


if __name__ == '__main__':
    unittest.main()
