"""Read-only BOOT source, coverage and placement verification (Pillow)."""
import hashlib
import json
import sys
import zipfile
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = root / 'assets/pixel/boot/source'
game = source.parent / 'game'
checks = []
def check(name, ok):
    checks.append({'test': name, 'passed': bool(ok)})
    print(('PASS ' if ok else 'FAIL ') + name)

if len(sys.argv) > 1:
    with zipfile.ZipFile(sys.argv[1]) as pack:
        check('supplied sources retained byte for byte', all(hashlib.sha256(pack.read(n)).digest() == hashlib.sha256((source / Path(n).name).read_bytes()).digest() for n in pack.namelist() if not n.endswith('/')))
catalog = json.loads((game / 'props_manifest.json').read_text(encoding='utf-8'))
placements = json.loads((root / 'data/boot_dressing.json').read_text())
level = json.loads((root / 'data/levels/boot_01.json').read_text(encoding='utf-8'))
check('all twelve distinct prop types placed once', sorted(p['id'] for p in placements) == list(range(1, 13)))
check('standing props contact actual floors', all(any(f[0] <= p['x'] <= f[0]+f[2] and f[1] == p['y'] for f in level['platforms']) for p in placements if not p.get('wall') and not p.get('hang')))
check('atlas regions remain within padded atlas', Image.open(game/'props.png').size == (512,192) and all(0 <= p['atlas_rect'][0] and p['atlas_rect'][0]+p['atlas_rect'][2] <= 512 and 0 <= p['atlas_rect'][1] and p['atlas_rect'][1]+p['atlas_rect'][3] <= 192 for p in catalog))
mid = Image.open(game/'mid-continuous.png').convert('RGBA')
check('single world-sized continuous midground', mid.size == (1024,640))
check('real transparent observation windows', sum(a == 0 for a in mid.getchannel('A').tobytes()) > 20000)
check('solid opaque wall architecture', sum(a == 255 for a in mid.getchannel('A').tobytes()) > 500000)
far = Image.open(game/'far.png')
check('far covers full parallax sampling domain', far.width >= 704*.15+352 and far.height >= 400*.15+272)
check('terrain sizes match existing collision thicknesses', all(Image.open(game/name).size == (1024,height) for name,height in [('walkway.png',16),('foundation-32.png',32),('foundation.png',48)]))
report = {'passed': all(c['passed'] for c in checks), 'tests': checks}
(root/'artifacts/boot-source-qa.json').write_text(json.dumps(report,indent=2)+'\n')
sys.exit(0 if report['passed'] else 1)
