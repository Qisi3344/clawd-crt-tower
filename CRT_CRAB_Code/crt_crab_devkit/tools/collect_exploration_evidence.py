"""Collect successful local QA output and verify the native-frame recordings."""
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'artifacts'
DEST=ROOT/'docs/exploration_evidence'
REPORTS=['six-link-state-qa','exploration-state-qa','chapter-qa-headless','chapter-qa-visual',
         'controls-qa-headless','controls-qa-visual','touch-route-qa-headless','touch-route-qa-visual',
         'stage2-qa-headless','stage2-qa-visual','story-qa-headless','story-qa-visual',
         'ecology-qa-headless','ecology-qa-visual','unlock-qa-visual','pet-gacha-qa','sideview-qa-headless']
CAPTURES=['controls-choice','controls-landscape-fit','controls-local-map','touch-route-boot-key',
          'touch-route-pause-settings','exploration-popup-upper','exploration-recycle-lower',
          'exploration-recycle-upper','exploration-signal-ready','exploration-error-core',
          'exploration-ending-delivered','story-intro-repair']
manifest={'scope':'Windows native Godot QA; no mobile hardware or first-time-human-play claim',
          'reports':[],'recordings':[]}
DEST.mkdir(exist_ok=True)
for name in REPORTS:
    source=SOURCE/(name+'.json')
    data=json.loads(source.read_text(encoding='utf-8-sig'))
    if data.get('passed') is not True: raise SystemExit('Failed report: '+name)
    count=len(data.get('tests',data.get('checks',[])))
    manifest['reports'].append({'name':name,'passed':True,'checks':count})
    shutil.copyfile(source,DEST/source.name)
for name in CAPTURES:
    shutil.copyfile(SOURCE/(name+'.png'),DEST/(name+'.png'))
shutil.copyfile(SOURCE/'performance.json',DEST/'performance.json')
campaign=json.loads((SOURCE/'chapter-qa-visual.json').read_text(encoding='utf-8-sig'))
ffprobe=shutil.which('ffprobe')
if not ffprobe: raise SystemExit('ffprobe is required to verify encoded evidence.')
for name in ['popup-v2','recycle-v2','signal-v2','error-v2']:
    path=DEST/(name+'.mp4')
    result=subprocess.run([ffprobe,'-v','error','-select_streams','v:0','-show_entries',
                           'stream=width,height,nb_frames,duration','-of','json',str(path)],
                          check=True,capture_output=True,text=True)
    stream=json.loads(result.stdout)['streams'][0]
    frames=int(stream['nb_frames'])
    if frames!=campaign['clips'][name]: raise SystemExit('Recording frame count differs: '+name)
    manifest['recordings'].append({'name':path.name,'frames':frames,'duration_seconds':float(stream['duration']),
                                   'size':[stream['width'],stream['height']],
                                   'source':'Native 320x240 gameplay, every sixth fixed-60 step; nearest-neighbour 2x encoding; no audio',
                                   'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
(DEST/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'reports':len(manifest['reports']),'recordings':manifest['recordings']},ensure_ascii=True))
