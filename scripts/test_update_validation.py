import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class UpdateValidationTests(unittest.TestCase):
    def test_native_policy_and_installer_lifecycle(self):
        if not shutil.which('javac') or not shutil.which('java'):
            self.skipTest('JDK required for native updater policy regression')
        root = Path(__file__).resolve().parents[1]
        source = root / 'android/app/src/main/java/com/hongguo/tv'
        test = root / 'android/app/src/test/java/com/hongguo/tv/UpdateValidationTest.java'
        with tempfile.TemporaryDirectory() as output:
            subprocess.run(['javac', '-d', output, str(source / 'UpdateValidation.java'),
                            str(source / 'UpdateInstallSession.java'), str(test)], check=True)
            subprocess.run(['java', '-cp', output, 'com.hongguo.tv.UpdateValidationTest'], check=True)


if __name__ == '__main__':
    unittest.main()
