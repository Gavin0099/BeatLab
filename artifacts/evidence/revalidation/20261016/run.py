from pathlib import Path
import subprocess,sys,time,json
b=Path(__file__).resolve().parent
name=sys.argv[1];cmd=sys.argv[2:]
log=b/(name+'.log');receipt=b/(name+'-command.json')
assert not log.exists() and not receipt.exists(), 'Use a new attempt name'
start=time.time()
with log.open('w') as out:r=subprocess.run(cmd,stdout=out,stderr=subprocess.STDOUT)
value={'command':cmd,'cwd':str(Path.cwd()),'exit_code':r.returncode,'started_at':start,'finished_at':time.time(),'local_mac':True}
receipt.write_text(json.dumps(value,indent=2)+'\n')
print(json.dumps(value))
if r.returncode:print(log.read_text()[-5000:])
sys.exit(r.returncode)
