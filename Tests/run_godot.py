import os, shutil, subprocess, sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
env=os.environ.copy()
env['APPDATA']=str(root/'Tests/runtime')
godot = env.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4')
if not godot:
 candidate = Path.home()/'Desktop/Godot_v4.7.2-stable_win64.exe'
 if candidate.is_file(): godot = str(candidate)
if not godot:
 sys.exit('Set GODOT_BIN to your Godot executable or add godot to PATH.')
args=sys.argv[1:]
tag=Path(args[args.index('--script')+1]).stem if '--script' in args else 'v005_run'
log=root/'Tests'/f'{tag}.log'
with log.open('w',encoding='utf-8') as stream:
 result=subprocess.Popen([godot,'--path',str(root),*args],env=env,stdout=stream,stderr=stream)
 try: result.wait(timeout=120)
 except subprocess.TimeoutExpired:
  result.kill();result.wait()
output=log.read_text(encoding='utf-8',errors='replace')
print(output[-12000:])
sys.exit(result.returncode or (1 if 'SCRIPT ERROR:' in output or 'Lambda capture' in output else 0))
