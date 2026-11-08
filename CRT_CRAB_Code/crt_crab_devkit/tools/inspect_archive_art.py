"""Read-only source, atlas and geometry validation for the ARCHIVE integration."""
import hashlib
import json
import sys
import zipfile
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
checks=[]
def check(name,ok):
    checks.append({'test':name,'passed':bool(ok)})
    print(('PASS ' if ok else 'FAIL ')+name)

source=ROOT/'assets/pixel/archive/source'
if len(sys.argv)>1:
    with zipfile.ZipFile(sys.argv[1]) as pack:
        files=[n for n in pack.namelist() if n.endswith(('.png','.md','.json'))]
        check('all supplied production sources are retained byte for byte',all(hashlib.sha256(pack.read(n)).digest()==hashlib.sha256((source/Path(n).name).read_bytes()).digest() for n in files))
game=ROOT/'assets/pixel/archive/game'
manifest=json.loads((game/'manifest.json').read_text(encoding='utf-8'))
atlas=Image.open(game/'props.png').convert('RGBA')
check('12 props fit a padded 512x128 atlas',len(manifest['props'])==12 and atlas.size==(512,128) and all(0<=p['rect'][0]<p['rect'][0]+p['rect'][2]<=512 and 0<=p['rect'][1]<p['rect'][1]+p['rect'][3]<=128 for p in manifest['props']))
check('game prop silhouettes have clean binary alpha',set(atlas.getchannel('A').tobytes())<={0,255})
placements=json.loads((ROOT/'data/archive_dressing.json').read_text(encoding='utf-8'))
level=json.loads((ROOT/'data/levels/archive_01.json').read_text(encoding='utf-8'))
check('all 12 prop identities are represented',set(p['id'] for p in placements)==set(range(1,13)))
standing=[p for p in placements if not p.get('hang') and not p.get('stowed')]
check('every standing prop uses an existing actual floor',all(any(f[0]<=p['position'][0]<=f[0]+f[2] and f[1]==p['position'][1] for f in level['platforms']) for p in standing))
check('all placements are fixed integer world positions',all(all(isinstance(v,int) for v in p['position']) for p in placements))
check('all three archive regions receive decorations',set(p['area'] for p in placements)=={'upper','main','lower'})
check('original sources are excluded from runtime imports',(source/'.gdignore').exists())
far=Image.open(game/'far.png')
check('single nonrepeating far image covers the full parallax domain',not manifest['far_repeat'] and far.width>=704*.15+352 and far.height>=400*.15+272)
provenance={'checks':checks,'passed':all(c['passed'] for c in checks),'source_far_edge_rgb_mean':manifest['source_far_edge_rgb_mean'],'runtime_images':[{'file':p.name,'size':list(Image.open(p).size),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(game.glob('*.png'))]}
(ROOT/'artifacts/archive-source-qa.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
sys.exit(0 if provenance['passed'] else 1)
