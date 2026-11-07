"""Export a reviewable before/after diagram from the actual RECYCLE definition."""
import html
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
d=json.loads((ROOT/'data/levels/recycle_01.json').read_text(encoding='utf-8'))
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="1540" height="900" viewBox="0 0 1540 900">',
       '<rect width="1540" height="900" fill="#17121f"/>',
       '<style>text{font-family:Microsoft YaHei,sans-serif;fill:#f4e7cf;font-size:18px}.minor{font-size:14px;fill:#aab4b2}.area{fill:#292d38;stroke:#59606c;stroke-dasharray:5 5}</style>',
       '<defs><marker id="arrow" markerWidth="8" markerHeight="8" refX="7" refY="3" orient="auto"><path d="M0,0 L7,3 L0,6" fill="#e89aaa"/></marker></defs>']
def text(x,y,s,css=''):
    parts.append(f'<text x="{x}" y="{y}" class="{css}">{html.escape(s)}</text>')
text(32,38,'RECYCLE · 原房间链与连续三层回环')
text(32,72,'旧布局：四间高度 240 的小房间')
old=[('sorter','分拣区',60,130),('well','磁吸井',60,300),('cache','重构室',60,470),('tunnel','暗道',220,300)]
for id,name,x,y in old:
    parts.append(f'<rect x="{x}" y="{y}" width="132" height="90" rx="5" fill="#292033" stroke="#a88496"/>')
    text(x+12,y+34,name);text(x+12,y+64,id,'minor')
for x1,y1,x2,y2 in [(126,220,126,300),(126,390,126,470),(192,345,220,345)]:
    parts.append(f'<path d="M{x1},{y1} L{x2},{y2}" stroke="#e89aaa" stroke-width="2" marker-end="url(#arrow)"/>')
text(40,622,'旧通路需要 E 切换房间；没有实体回环。','minor')
text(438,72,'新布局：1024 × 768 · 一个物理世界 / 一个 320 × 240 视口')
ox,oy=438,104
parts.append(f'<g transform="translate({ox},{oy})">')
for a in d['areas']:
    x,y,w,h=a['rect']
    parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" class="area"/>')
    text(x+10,y+25,a['name']+' / '+a['floor'],'minor')
for p in d['platforms']:
    x,y,w,h,*_=p
    parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#788b91"/>')
for l in d['ladders']:
    x,y,b=l['x'],l['top'],l['bottom']
    for side in [-5,5]: parts.append(f'<path d="M{x+side},{y} V{b}" stroke="#8dcabb" stroke-width="2"/>')
    for rung in range(y,b,12): parts.append(f'<path d="M{x-5},{rung} H{x+5}" stroke="#8dcabb" stroke-width="2"/>')
for gate in d['doors']:
    x,y=gate['position']
    parts.append(f'<path d="M{x},{y} V{y-gate["height"]}" stroke="#efcd79" stroke-width="7" stroke-dasharray="7 4"/>')
for c in d['chests']:
    x,y=c['position']
    parts.append(f'<rect x="{x-7}" y="{y-14}" width="14" height="12" fill="#ffc478"/>')
for c in d['connections']:
    x,y=c['position'];parts.append(f'<circle cx="{x}" cy="{y}" r="5" fill="#62b8c1"/>')
route=[(32,448),(448,448),(448,688),(592,688),(592,608),(592,688),(672,688),(976,688),(976,208),(608,208),(768,208),(976,208),(976,64),(80,64),(80,448)]
points=' '.join(f'{x},{y-16}' for x,y in route)
parts.append(f'<polyline points="{points}" fill="none" stroke="#e89aaa" stroke-opacity=".85" stroke-width="3" marker-end="url(#arrow)"/>')
parts.append('</g>')
text(32,716,'青：实体梯子与通路节点','minor')
text(32,750,'金：需要真实机关输出的门','minor')
text(32,784,'粉线：已通过原生输入验证的主回环','minor')
text(32,844,'跨 CRT 仍走原连接；右图没有房间切换或任意传送。','minor')
parts.append('</svg>')
target=ROOT/'docs/exploration_evidence/recycle-topology.svg'
target.write_text('\n'.join(parts),encoding='utf-8')
print(target)
