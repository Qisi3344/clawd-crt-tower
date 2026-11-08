"""Read-only POP-UP production source and placement verification (Pillow)."""
import hashlib
import json
import sys
import zipfile
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = root / 'assets/pixel/popup/source'
game = source.parent / 'game'
checks = []
def check(name, ok):
    checks.append({'test': name, 'passed': bool(ok)})
    print(('PASS ' if ok else 'FAIL ') + name)

if len(sys.argv) > 1:
    with zipfile.ZipFile(sys.argv[1]) as pack:
        check('all supplied source files preserved byte for byte', all(hashlib.sha256(pack.read(n)).digest() == hashlib.sha256((source / Path(*Path(n).parts[1:])).read_bytes()).digest() for n in pack.namelist() if not n.endswith('/')))
catalog = json.loads((game/'manifest.json').read_text(encoding='utf-8'))['props']
placements = json.loads((root/'data/popup_dressing.json').read_text())
level = json.loads((root/'data/levels/popup_01.json').read_text(encoding='utf-8'))
check('all twelve prop identities retained once', sorted(p['id'] for p in placements) == list(range(1,13)))
check('fixed props cover all five actual areas', {p['area'] for p in placements} == {'loft','shaft','hall','east','drain'})
check('standing props contact actual collision floors', all(any(f[0] <= p['x'] <= f[0]+f[2] and f[1] == p['y'] for f in level['platforms']) for p in placements if not p.get('wall') and not p.get('hang')))
atlas = Image.open(game/'props.png').convert('RGBA')
check('all atlas regions fit padded 512x128 texture', atlas.size == (512,128) and all(0 <= p['rect'][0] and p['rect'][0]+p['rect'][2] <= 512 and 0 <= p['rect'][1] and p['rect'][1]+p['rect'][3] <= 128 for p in catalog))
check('prop silhouettes have binary alpha', set(atlas.getchannel('A').tobytes()) <= {0,255})
mid = Image.open(game/'mid-continuous.png').convert('RGBA')
check('one continuous 1024x768 midground', mid.size == (1024,768))
check('open skyline exposes distant city', mid.getpixel((512,61))[3] == 0 and sum(a == 0 for a in mid.getchannel('A').tobytes()) > 45000)
check('painted buildings and repair bays remain opaque', sum(a == 255 for a in mid.getchannel('A').tobytes()) > 300000)
capsule = Image.open(game/'capsule.png').convert('RGBA')
check('sealed capsule is a readable separate device', capsule.height >= 70 and capsule.width >= 32 and capsule.height <= 108 and set(capsule.getchannel('A').tobytes()) <= {0,255})
far = Image.open(game/'far.png')
check('framed far image covers the complete sampling domain', far.width >= 160+704*.5+352 and far.height >= 528*.15+272)
check('dedicated materials match collision heights', all(Image.open(game/name).size == (1024,height) for name,height in [('walkway.png',16),('foundation-32.png',32),('foundation.png',48)]))
report = {'passed': all(c['passed'] for c in checks), 'tests': checks}
(root/'artifacts/popup-source-qa.json').write_text(json.dumps(report,indent=2)+'\n')
sys.exit(0 if report['passed'] else 1)
