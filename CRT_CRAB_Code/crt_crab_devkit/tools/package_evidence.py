"""Package real Godot GPU captures, never concept art or synthesized gameplay."""
import json
import shutil
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'artifacts'
OUT=ROOT/'docs/six_link_evidence'
OUT.mkdir(parents=True,exist_ok=True)

for name in ['six-link-state-qa.json','chapter-qa-headless.json','chapter-qa-visual.json','ecology-qa-headless.json','ecology-qa-visual.json','story-qa-headless.json','story-qa-visual.json','stage2-qa-headless.json','stage2-qa-visual.json','sideview-qa-headless.json','sideview-qa-visual.json','environment-metrics-visual.json','environment-metrics-headless.json','pet-gacha-qa.json','unlock-qa-visual.json']:
    if (ART/name).exists(): shutil.copy2(ART/name,OUT/name)
for pattern in ['chapter-*.png','story-intro-*.png','environment-front.png','environment-back.png','environment-left.png','environment-right.png','environment-top.png']:
    for path in ART.glob(pattern): shutil.copy2(path,OUT/path.name)

for report_name in ['chapter-qa-visual.json','ecology-qa-visual.json']:
    report=json.loads((ART/report_name).read_text(encoding='utf-8-sig'))
    if not report['passed']: raise RuntimeError('Refusing to package failed evidence: '+report_name)
    for name,count in report.get('clips',{}).items():
        if not count: continue
        if report_name.startswith('ecology') and name in ['boot','archive']: continue
        frames=[]
        for index in range(count):
            path=ART/'chapter-clips'/name/f'{index:04d}.png'
            frames.append(Image.open(path).convert('P',palette=Image.Palette.ADAPTIVE))
        frames[0].save(OUT/f'{name}-gameplay.gif',save_all=True,append_images=frames[1:],duration=100,loop=0,optimize=True)
        print(name,count,'real GPU frames')
print('Packaged real GPU evidence in',OUT)
