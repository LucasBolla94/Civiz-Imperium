"""Rebuild the portable and editable archives from the reviewed workspace."""
import os
import subprocess
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
build = root / 'Builds/Civiz-Imperium-V0.0.5'
env = os.environ.copy()
env['APPDATA'] = str(root / 'Tests/runtime-portable')
env['CIVIZ_CAPTURE'] = str(root / 'Tests/v005_portable.png')
result = subprocess.run(
    [str(build / 'Civiz Imperium V0.0.5.exe'), '--script', str(root / 'Tests/test_v005_portable.gd')],
    cwd=build, env=env, capture_output=True, text=True, timeout=60,
)
print(result.stdout, result.stderr)
assert result.returncode == 0 and 'passed' in result.stdout and 'SCRIPT ERROR' not in result.stderr

windows = root / 'Builds/Civiz-Imperium-V0.0.5-Windows.zip'
with zipfile.ZipFile(windows, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for path in sorted(build.rglob('*')):
        if path.is_file():
            archive.write(path, Path(build.name) / path.relative_to(build))

project = root / 'Builds/Civiz-Imperium-V0.0.5-Projeto.zip'
with zipfile.ZipFile(project, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for directory in ['Scripts', 'Scenes', 'Assets', 'Tests']:
        for path in sorted((root / directory).rglob('*')):
            if not path.is_file():
                continue
            if directory == 'Tests' and (path.parent != root / 'Tests' or path.suffix not in ['.gd', '.uid', '.py']):
                continue
            archive.write(path, Path('civyz') / path.relative_to(root))
    for path in sorted(root.iterdir()):
        if path.is_file() and (path.suffix in ['.md', '.godot', '.cfg', '.svg'] or path.name in ['.gitignore', '.gitattributes', '.editorconfig']):
            archive.write(path, Path('civyz') / path.name)

for path in [windows, project]:
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
    print(path.name, path.stat().st_size, 'bytes; CRC verified')
