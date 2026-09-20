"""Build and verify V0.0.6 from a committed snapshot, excluding unrelated local edits."""
import os
import shutil
import subprocess
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = '0.0.6'
build = root / f'Builds/Civiz-Imperium-V{version}'
build.mkdir(parents=True, exist_ok=True)
project_zip = root / f'Builds/Civiz-Imperium-V{version}-Projeto.zip'
subprocess.run(['git', 'archive', '--format=zip', '--prefix=civyz/', '-o', str(project_zip), 'HEAD'], cwd=root, check=True)
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
# A fresh directory prevents stale imports and unrelated files entering a release.
snapshot_root = root / 'Builds' / f'release-{revision[:12]}'
snapshot_root.mkdir(exist_ok=True)
with zipfile.ZipFile(project_zip) as archive:
    for member in archive.infolist():
        assert (snapshot_root / member.filename).resolve().is_relative_to(snapshot_root.resolve())
    archive.extractall(snapshot_root)
snapshot = snapshot_root / 'civyz'
env = os.environ.copy()
env['APPDATA'] = str(root / 'Tests/runtime-portable')
env['CIVIZ_SILENT_TEST'] = '1'
env['CIVIZ_CAPTURE'] = str(root / 'Tests/v006_portable.png')
godot = env.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4')
if not godot:
    godot = str(Path.home() / 'Desktop/Godot_v4.7.2-stable_win64.exe')
assert Path(godot).is_file(), 'Set GODOT_BIN to the Godot executable.'

def run(args, cwd, tag, timeout=180):
    log = root / 'Tests' / f'package_v006_{tag}.log'
    with log.open('w', encoding='utf-8') as stream:
        result = subprocess.run(args, cwd=cwd, env=env, stdout=stream, stderr=stream, timeout=timeout)
    output = log.read_text(encoding='utf-8', errors='replace')
    print(f'{tag}: exit {result.returncode}', flush=True)
    if result.returncode or 'SCRIPT ERROR' in output or 'Failed to load' in output:
        raise RuntimeError(output[-12000:])
    return output

print(f'Building committed revision {revision}', flush=True)
run([godot, '--headless', '--path', str(snapshot), '--editor', '--import'], snapshot, 'import')
pck = build / f'Civiz Imperium V{version}.pck'
run([godot, '--headless', '--path', str(snapshot), '--export-pack', f'Windows V{version}', str(pck)], snapshot, 'export')
exe = build / f'Civiz Imperium V{version}.exe'
shutil.copy2(godot, exe)
for name in ['README.md', 'VALIDACAO_V0.0.6.md', 'GODOT-LICENSE.txt', f'PLANO_V{version}.md', f'ASSETS_V{version}.md']:
    shutil.copy2(snapshot / name, build / name)
(build / 'LEIA-ME.txt').write_text(
    f'Civiz Imperium V{version}\n\n'
    f'Abra Civiz Imperium V{version}.exe. Mantenha o arquivo .pck ao lado.\n'
    'WASD: mover; Q/E: zoom suave; Home: centralizar; Espaço: pausar.\n'
    'Expansão: Ctrl + roda ajusta o pincel; Shift + arraste pinta o percurso.\n'
    'Esc fecha menus; depois abre Salvar jogo / Fechar jogo.\n'
    'Hortas novas exigem depósito de comida nível 2. Hortas antigas são preservadas.\n'
    'Cortar agora: frutas perdidas ao iniciar; cancelável antes da primeira machadada.\n'
    'Balões mostram impedimentos; melhorias mostram benefícios antes de gastar.\n'
    'Jogar: cinco ilhas independentes. O save antigo é importado sem apagar o original.\n'
    'Configurações: música, efeitos, idioma e vídeo com reversão em 15 segundos.\n'
    'Tela cheia usa a resolução nativa do monitor.\n'
    f'Código da versão: {revision}\n', encoding='utf-8')
output = run([str(exe), '--script', str(snapshot / 'Tests/test_v006_portable.gd')], build, 'portable', 60)
assert 'passed' in output, output
windows_zip = root / f'Builds/Civiz-Imperium-V{version}-Windows.zip'
with zipfile.ZipFile(windows_zip, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for name in [exe.name, pck.name, 'LEIA-ME.txt', 'README.md', 'VALIDACAO_V0.0.6.md', 'GODOT-LICENSE.txt', f'PLANO_V{version}.md', f'ASSETS_V{version}.md']:
        archive.write(build / name, Path(build.name) / name)
for path in [windows_zip, project_zip]:
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
    print(path.name, path.stat().st_size, 'bytes; CRC verified', flush=True)
