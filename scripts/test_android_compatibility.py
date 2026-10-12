import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'android/app/src/main/res'
ANDROID = '{http://schemas.android.com/apk/res/android}'


def styles(qualifier):
    return {style.get('name'): style for style in ET.parse(RES / qualifier / 'styles.xml').getroot()}


class AndroidCompatibilityTests(unittest.TestCase):
    def test_api_26_theme_uses_only_common_system_bar_attributes(self):
        base = styles('values')
        common = base['AppSystemBarThemeBase']
        self.assertEqual(common.get('parent'), '@android:style/Theme.Black.NoTitleBar')
        self.assertNotIn('android:windowLightNavigationBar', {item.get('name') for item in common})
        self.assertEqual(base['AppSystemBarTheme'].get('parent'), 'AppSystemBarThemeBase')
        for qualifier in ('values', 'values-night'):
            for name in ('LaunchTheme', 'NormalTheme'):
                self.assertEqual(styles(qualifier)[name].get('parent'), 'AppSystemBarTheme')

    def test_api_27_theme_preserves_navigation_icon_policy(self):
        qualified = styles('values-v27')['AppSystemBarTheme']
        self.assertEqual(qualified.get('parent'), 'AppSystemBarThemeBase')
        self.assertEqual({item.get('name'): item.text for item in qualified},
                         {'android:windowLightNavigationBar': 'false'})

    def test_activity_uses_flutter_predictive_back_and_keeps_remote_key_dispatch(self):
        manifest = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml').getroot()
        activity = next(item for item in manifest.findall('application/activity')
                        if item.get(ANDROID + 'name') == '.MainActivity')
        self.assertEqual(activity.get(ANDROID + 'enableOnBackInvokedCallback'), 'true')
        source = (ROOT / 'android/app/src/main/kotlin/com/hongguo/tv/MainActivity.kt').read_text()
        self.assertIn('class MainActivity : FlutterActivity()', source)
        self.assertNotIn('override fun onBackPressed', source)
        self.assertNotIn('override fun commitBackGesture', source)
        self.assertIn('override fun dispatchKeyEvent(event: KeyEvent)', source)
        self.assertIn('event.keyCode == KeyEvent.KEYCODE_BACK || event.keyCode == KeyEvent.KEYCODE_ESCAPE', source)
        self.assertIn('event.action == KeyEvent.ACTION_UP && !event.isCanceled', source)


if __name__ == '__main__':
    unittest.main()
