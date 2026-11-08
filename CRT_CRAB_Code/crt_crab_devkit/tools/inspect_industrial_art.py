"""Read-only RECYCLE/SIGNAL art, source-byte and floor-anchor audit (Pillow)."""
import hashlib
import json
import sys
import zipfile
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
checks = []
source_hashes = {}
def check(name, ok):
    checks.append({'test': name, 'passed': bool(ok)})
    print(('PASS ' if ok else 'FAIL ') + name)

for index, key in enumerate(['recycle', 'signal']):
    source = root/'assets/pixel'/key/'source'
    game = source.parent/'game'
    if len(sys.argv) > index+1:
        with zipfile.ZipFile(sys.argv[index+1]) as pack:
            entries = [n for n in pack.namelist() if not n.endswith('/')]
            hashes = {str(Path(*Path(n).parts[1:])): hashlib.sha256(pack.read(n)).hexdigest() for n in entries}
            source_hashes[key] = hashes
            check(key+' supplied source bytes match ZIP', all(hashlib.sha256((source/path).read_bytes()).hexdigest() == digest for path,digest in hashes.items()))
    catalog = json.loads((game/'manifest.json').read_text(encoding='utf-8'))['props']
    rows = json.loads((root/'data'/f'{key}_dressing.json').read_text())
    level = json.loads((root/'data/levels'/f'{key}_01.json').read_text(encoding='utf-8'))
    check(key+' retains all twelve prop identities', {r['id'] for r in rows} == set(range(1,13)))
    check(key+' covers all named areas with fixed props', {r['area'] for r in rows} == {a['id'] for a in level['areas']})
    check(key+' standing props contact real floors', all(any(f[0] <= r['x'] <= f[0]+f[2] and f[1] == r['y'] for f in level['platforms']) for r in rows if not r.get('wall') and not r.get('hang')))
    atlas = Image.open(game/'props.png').convert('RGBA')
    check(key+' atlas regions fit 512x128', atlas.size == (512,128) and all(0 <= p['rect'][0] and p['rect'][0]+p['rect'][2] <= 512 and 0 <= p['rect'][1] and p['rect'][1]+p['rect'][3] <= 128 for p in catalog))
    check(key+' prop alpha is binary', set(atlas.getchannel('A').tobytes()) <= {0,255})
    mid = Image.open(game/'mid-continuous.png').convert('RGBA')
    check(key+' one full-world scene canvas', mid.size == (1024,768))
    check(key+' broad open depth, not little wall windows', sum(a == 0 for a in mid.getchannel('A').tobytes()) > 50000)
    if key == 'recycle':
        check('recycle isolated well opening has no painted white background', mid.getpixel((665,400))[3] == 0)
    check(key+' painted apparatus stays opaque', sum(a == 255 for a in mid.getchannel('A').tobytes()) > 300000)
    far = Image.open(game/'far.png')
    check(key+' single far texture covers bounded sampling', far.width >= 352 and far.height >= 40+528*.15+272)
    check(key+' materials match 16/32/48 collision heights', all(Image.open(game/name).size == (1024,height) for name,height in [('walkway.png',16),('foundation-32.png',32),('foundation.png',48)]))

report = {'passed': all(c['passed'] for c in checks), 'tests': checks, 'supplied_source_sha256': source_hashes}
(root/'artifacts/industrial-source-qa.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
sys.exit(0 if report['passed'] else 1)
