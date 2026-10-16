import argparse
import re
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

from app_build import BuildVariant, add_variant_argument

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
add_variant_argument(parser)
options = parser.parse_args()
variant = BuildVariant(options.all_sources)

match = re.search(r'^version:\s*([\w.+-]+)\s*$', (root / 'pubspec.yaml').read_text(encoding='utf-8'), re.MULTILINE)
if not match:
    raise SystemExit('pubspec.yaml 缺少合法版本号。')
release = match.group(1).split('+')[0]

compiler = None
for candidate in [
    shutil.which('ISCC'),
    r'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    r'C:\Program Files\Inno Setup 6\ISCC.exe',
]:
    if candidate and Path(candidate).is_file():
        compiler = candidate
        break
if compiler is None:
    raise SystemExit('未找到 Inno Setup 编译器 ISCC.exe。')

bundle = root / 'build' / 'windows' / 'x64' / 'runner' / 'Release'
executable = variant.slug + '.exe'
if not (bundle / executable).is_file():
    raise SystemExit('缺少 Windows 构建产物：' + str(bundle / executable))

output = root / 'dist' / 'windows'
output.mkdir(parents=True, exist_ok=True)
icon = root / 'windows' / 'runner' / 'resources' / 'app_icon.ico'

language = Path(compiler).parent / 'Languages' / 'ChineseSimplified.isl'
if not language.is_file():
    source = ('https://raw.githubusercontent.com/jrsoftware/issrc/main/'
              'Files/Languages/Unofficial/ChineseSimplified.isl')
    try:
        with urllib.request.urlopen(source, timeout=30) as response:
            language.write_bytes(response.read())
    except Exception as error:
        print('中文安装界面未取得，改用默认语言：%s' % error, file=sys.stderr)

subprocess.run([
    str(compiler),
    '/DAppVersion=' + release,
    '/DAppSlug=' + variant.slug,
    '/DSourceDir=' + str(bundle),
    '/DOutputDir=' + str(output),
    '/DAppExe=' + executable,
    '/DIconFile=' + str(icon),
    str(root / 'scripts' / 'windows_installer.iss'),
], cwd=root, check=True)

installer = output / f'{variant.slug}-{release}-windows-x64.exe'
if not installer.is_file():
    raise SystemExit('安装程序未生成：' + str(installer))
print(installer)
