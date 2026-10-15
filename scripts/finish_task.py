import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

from sync_source import source_files


@dataclass(frozen=True)
class TaskSnapshot:
    files: int
    total_bytes: int


def finish_task(source, message):
    source = source.resolve()
    if not message.strip():
        raise ValueError('请填写本次完成的变更说明')
    names = sorted(path.as_posix() for path in source_files(source))
    for name in names:
        if not (source / name).is_file():
            raise ValueError('收录清单存在缺失文件：' + name)
    return TaskSnapshot(
        files=len(names),
        total_bytes=sum((source / name).stat().st_size for name in names),
    )


def main():
    source = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description='校验可发布的干净源码清单，不生成副本或压缩包，不执行任何 Git 操作。'
    )
    parser.add_argument('--message', required=True, help='本次实际完成的变更')
    options = parser.parse_args()
    try:
        result = finish_task(source, options.message)
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1
    print(f'干净源码：{result.files} 个文件，{result.total_bytes / 1024:.1f} KB')
    print('源码目录：' + str(source))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
