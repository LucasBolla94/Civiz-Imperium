"""Package a committed V0.0.6.1 snapshot and exercise the actual Windows bundle."""
import hashlib
import json
import os
import shutil
import subprocess
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = '0.0.6.1'
revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
build = root / f'Builds/Civiz-Imperium-V{version}'
build.mkdir(parents=True, exist_ok=True)
project_zip = root / f'Builds/Civiz-Imperium-V{version}-Projeto.zip'
subprocess.run(['git', 'archive', '--format=zip', '--prefix=civyz/', '-o', str(project_zip), revision], cwd=root, check=True)
snapshot_root = root / 'Builds' / f'release-{revision[:12]}'
snapshot_root.mkdir(exist_ok=True)
with zipfile.ZipFile(project_zip) as archive:
    for member in archive.infolist():
        assert (snapshot_root / member.filename).resolve().is_relative_to(snapshot_root.resolve())
    archive.extractall(snapshot_root)
snapshot = snapshot_root / 'civyz'
assert f'config/version="{version}"' in (snapshot / 'project.godot').read_text(encoding='utf-8')

env = os.environ.copy()
env['APPDATA'] = str(root / 'Tests/runtime-portable')
env['CIVIZ_SILENT_TEST'] = '1'
env['CIVIZ_CAPTURE'] = str(root / 'Tests/v0061_portable.png')
godot = env.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4')
if not godot:
    godot = str(Path.home() / 'Desktop/Godot_v4.7.2-stable_win64.exe')
assert Path(godot).is_file(), 'Set GODOT_BIN to the Godot executable.'

def run(args, cwd, tag, timeout=180):
    log = root / 'Tests' / f'package_v0061_{tag}.log'
    with log.open('w', encoding='utf-8') as stream:
        result = subprocess.run(args, cwd=cwd, env=env, stdout=stream, stderr=stream, timeout=timeout)
    output = log.read_text(encoding='utf-8', errors='replace')
    print(f'{tag}: exit {result.returncode}', flush=True)
    if result.returncode or 'SCRIPT ERROR' in output or 'Failed to load' in output:
        raise RuntimeError(output[-12000:])
    return output

print(f'Building committed revision {revision}', flush=True)
run([godot, '--headless', '--path', str(snapshot), '--editor', '--import'], snapshot, 'import')
# Verify against the committed map/assets, independently of unrelated local edits.
for script in ['test_v0061_gold', 'test_v0061_port', 'test_v0061_merchant',
               'test_v0061_commerce', 'test_v0061_commerce_edges', 'test_v0061_islands',
               'test_v0061_workforce_edges', 'test_reused_terrain', 'test_workforce_bounds', 'test_responsive_ui']:
    run([godot, '--headless', '--path', str(snapshot), '--script', f'res://Tests/{script}.gd'], snapshot, script)
pck = build / f'Civiz Imperium V{version}.pck'
run([godot, '--headless', '--path', str(snapshot), '--export-pack', f'Windows V{version}', str(pck)], snapshot, 'export')
exe = build / f'Civiz Imperium V{version}.exe'
shutil.copy2(godot, exe)
documents = ['README.md', f'VALIDACAO_V{version}.md', 'GODOT-LICENSE.txt', f'PLANO_V{version}.md', f'ASSETS_V{version}.md']
for name in documents:
    shutil.copy2(snapshot / name, build / name)
licenses = build / 'Licencas'
licenses.mkdir(exist_ok=True)
for name in ['Atkinson-OFL.txt', 'Cinzel-OFL.txt']:
    shutil.copy2(snapshot / 'Assets/UI/Fonts' / name, licenses / name)
(build / 'LEIA-ME.txt').write_text(
    f'Civiz Imperium V{version}\n\n'
    f'Abra Civiz Imperium V{version}.exe. Mantenha o arquivo .pck ao lado.\n'
    'Base 3: investigar, abrir ouro, minerar, fundir e guardar cinco barras para construir o porto.\n'
    'Habitantes: equipes; Porto > Negociar: compra/venda física em lotes de dez unidades.\n'
    'Pedidos confirmados aguardam entrega, mesmo depois do prazo para novos negócios.\n'
    'Reconstrução: escolha diretamente um prédio em Construir; não é preciso investigar novamente.\n'
    'WASD: mover; Q/E: zoom suave; R: girar porto; Home: centralizar; Espaço: pausar.\n'
    'Aterro: Ctrl + roda ajusta o pincel; Shift + arraste pinta o percurso.\n'
    'Esc fecha painéis e depois abre o menu para salvar ou sair.\n'
    'Cinco ilhas independentes; salvamentos existentes são preservados.\n'
    'Consulte VALIDACAO_V0.0.6.1.md para evidências e estado da revisão humana.\n'
    f'Revisão do código: {revision}\n', encoding='utf-8')
output = run([str(exe), '--script', str(snapshot / 'Tests/test_v0061_portable.gd')], build, 'portable', 60)
assert 'V0.0.6.1 portable: passed' in output, output
windows_zip = root / f'Builds/Civiz-Imperium-V{version}-Windows.zip'
with zipfile.ZipFile(windows_zip, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    files = [build / name for name in [exe.name, pck.name, 'LEIA-ME.txt', *documents]]
    files.extend(sorted(licenses.glob('*.txt')))
    for path in files:
        archive.write(path, Path(build.name) / path.relative_to(build))
manifest = {'version': version, 'revision': revision, 'portable_test': 'passed', 'archives': {}}
for path in [windows_zip, project_zip]:
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
    manifest['archives'][path.name] = {'bytes': path.stat().st_size, 'sha256': hashlib.file_digest(path.open('rb'), 'sha256').hexdigest()}
    print(path.name, path.stat().st_size, 'bytes; CRC verified', flush=True)
(root / 'Builds/Civiz-Imperium-V0.0.6.1-manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
