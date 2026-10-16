from pathlib import Path
import shutil,json,hashlib,datetime
b=Path(__file__).resolve().parent
backup=Path.home()/'Library/Application Support/BeatLabEvidence/QA-REVALIDATE-01-20261016'
assert not backup.exists(), 'Refuse to overwrite a previous backup'
skip={'DerivedData','core-build','Intermediates.noindex','__pycache__'}
shutil.copytree(b,backup,symlinks=True,ignore=lambda folder,names:[n for n in names if n in skip])
entries=[]
for p in sorted(b.rglob('*')):
 relative=p.relative_to(b)
 if any(n in skip for n in relative.parts) or not p.is_file():continue
 h=hashlib.sha256(p.read_bytes()).hexdigest();other=backup/relative
 assert other.is_file() and hashlib.sha256(other.read_bytes()).hexdigest()==h,str(relative)
 entries.append({'path':str(relative),'sha256':h,'bytes':p.stat().st_size})
raw=json.dumps(entries,indent=2)+'\n'
for directory in [b,backup]:(directory/'retention-manifest.json').write_text(raw)
receipt={'checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':str(b),'backup':str(backup),'files_checked':len(entries),'manifest_sha256':hashlib.sha256(raw.encode()).hexdigest(),'copy_hashes_match':True,'excluded_rebuildable_caches':sorted(skip),'old_TestResults_recovered':False}
for directory in [b,backup]:(directory/'backup-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt))
