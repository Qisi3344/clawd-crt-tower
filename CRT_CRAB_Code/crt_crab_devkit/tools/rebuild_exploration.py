"""Build continuous layout v2 from immutable pre-refactor v4 definitions."""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEGACY = ROOT / 'data/legacy_v4'
FIELDS = ('platforms', 'ladders', 'blocks', 'plates', 'doors', 'chests',
          'crystals', 'breakables', 'enemies', 'terminals', 'mechanisms', 'animals', 'signs')
OFFSETS = {
    'boot': {'main': [0, 0]}, 'archive': {'main': [0, 0]},
    'popup': {'hall': [0, 240], 'shaft': [512, 0], 'loft': [0, 0]},
    'recycle': {'sorter': [0, 240], 'well': [512, 480], 'cache': [512, 0], 'tunnel': [0, 480]},
    'signal': {'diagnostic': [0, 240], 'relay': [320, 240], 'shaft': [704, 0]},
    'error': {'foyer': [0, 240], 'piston': [512, 240], 'diagnostic': [704, 0], 'boss': [352, 480]},
}

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def shifted(p, offset):
    return [p[0] + offset[0], p[1] + offset[1]]

def merge(name, size=(1024, 768)):
    old = read(LEGACY / f'{name}_01.json')
    rooms = old.get('rooms', {'main': old})
    out = {key: [] for key in FIELDS}
    out.update(size=list(size), background=name, layout_version=2, spawns={},
               areas=[], connections=[], tutorial_zones=[], room_portals=[],
               legacy_offsets=OFFSETS[name], legacy_entry=old.get('entry_room', 'main'))
    for room_id, room in rooms.items():
        offset = OFFSETS[name][room_id]
        for key in FIELDS:
            for raw in room.get(key, []):
                entry = copy.deepcopy(raw)
                if key == 'platforms':
                    entry[:2] = shifted(entry, offset)
                    entry = entry[:4] + [raw[1] < 208]
                elif key == 'ladders':
                    entry['x'] += offset[0]
                    entry['top'] += offset[1]
                    entry['bottom'] += offset[1]
                elif key == 'signs':
                    continue  # concise shared connection signs replace old keyboard instructions
                else:
                    for field in ('position', 'control', 'target', 'emitter'):
                        if field in entry:
                            entry[field] = shifted(entry[field], offset)
                    if 'path' in entry:
                        entry['path'] = [shifted(p, offset) for p in entry['path']]
                    entry['legacy_room'] = room_id
                out[key].append(entry)
        for key, pos in room['spawns'].items():
            out['spawns'][f'{room_id}:{key}'] = shifted(pos, offset)
        if 'boss' in room:
            out['boss'] = {'offset': offset}
    out['spawns']['entrance'] = out['spawns'][out['legacy_entry'] + ':entrance']
    out['spawns']['return'] = out['spawns'][out['legacy_entry'] + ':return']
    return out

def platform(d, x, y, w, h=16, one_way=True):
    d['platforms'].append([x, y, w, h, one_way])

def ladder(d, x, top, bottom):
    d['ladders'].append(dict(x=x, top=top, bottom=bottom))
    # A narrow one-way hatch lets S / touch-down cross each solid floor on this shaft.
    floors = []
    for p in d['platforms']:
        if not p[4] and p[0] <= x < p[0]+p[2] and top <= p[1] < bottom:
            left = x-16-p[0]
            right = p[0]+p[2]-(x+16)
            if left > 0: floors.append([p[0], p[1], left, p[3], False])
            floors.append([x-16, p[1], 32, p[3], True])
            if right > 0: floors.append([x+16, p[1], right, p[3], False])
        else:
            floors.append(p)
    d['platforms'] = floors

def gate(d, id, x, y, height, flag):
    d['doors'].append(dict(id=id, position=[x, y], height=height, requires=flag))

def area(d, id, name, rect, checkpoint, floor, landmark):
    d['areas'].append(dict(id=id, name=name, rect=rect, checkpoint=checkpoint, floor=floor, landmark=landmark))

def connect(d, id, a, b, p, label, requires=''):
    d['connections'].append(dict(id=id, **{'from': a, 'to': b}, position=p,
                                 label=label, requires=requires, bidirectional=True))

def mechanism(d, id):
    return next(e for e in d['mechanisms'] if e['id'] == id)

def simple_layers(name):
    d = merge(name, (1024, 640))
    platform(d, 768, 208, 256, 48, False)
    platform(d, 64, 64, 896)
    platform(d, 64, 448, 896, 32, False)
    ladder(d, 80, 64, 208)
    ladder(d, 576 if name == 'boot' else 736, 64, 208)
    ladder(d, 112, 208, 448)
    ladder(d, 608, 208, 448)
    flag = 'boot_gate_open' if name == 'boot' else 'signal_archive_gate'
    gate(d, name+'_upper_gate', 400 if name == 'boot' else 496, 64, 64, flag)
    gate(d, name+'_lower_gate', 400 if name == 'boot' else 496, 448, 192,
         'recycle_route_repaired' if name == 'boot' else flag)
    if name == 'boot':
        gate(d, 'upper_remote_lock', 656, 64, 64, 'signal_archive_gate')
        gate(d, 'lower_remote_lock', 656, 448, 192, 'signal_archive_gate')
    upper_name = '维护灯带' if name == 'boot' else '上层检索桥'
    main_name = '中央电源大厅' if name == 'boot' else '重压归档大厅'
    lower_name = '回访线路井' if name == 'boot' else '破损记录仓'
    area(d, 'upper', upper_name, [0, 0, 1024, 112], [96, 64], '上层', 'ring' if name == 'boot' else 'shelves')
    area(d, 'main', main_name, [0, 112, 1024, 176], d['spawns']['entrance'], '中层', 'ring' if name == 'boot' else 'shelves')
    area(d, 'lower', lower_name, [0, 288, 1024, 352], [112, 448], '下层', 'crane' if name == 'boot' else 'shelves')
    connect(d, 'upper_left', 'main', 'upper', [80, 208], '↑ '+upper_name)
    connect(d, 'upper_return', 'upper', 'main', [576 if name == 'boot' else 736, 64], '↓ 中央大厅', flag)
    connect(d, 'lower_left', 'main', 'lower', [112, 208], '↓ '+lower_name)
    connect(d, 'lower_return', 'lower', 'main', [608, 448], '↑ 返回大厅', 'recycle_route_repaired' if name == 'boot' else flag)
    d['signs'] += [[188, 396, '封存线路 / 修复后形成回环']]
    d['areas'][1]['landmark_position']=[240 if name=='boot' else 320,144]
    if name == 'boot':
        d['tutorial_zones'] = [dict(id=k, rect=r) for k,r in [
            ('jump',[112,160,80,80]),('push',[206,160,84,80]),('ladder',[456,130,45,90]),
            ('chest',[490,110,50,60]),('travel',[558,160,64,80]),('array',[624,160,32,80])]]
    else:
        d['tutorial_zones'] = [dict(id='attack',rect=[104,155,80,90]),dict(id='heavy',rect=[300,90,128,128])]
    return d

boot = simple_layers('boot')
archive = simple_layers('archive')

popup = merge('popup', (1024, 768))
platform(popup,480,448,544,32,False)
platform(popup,320,208,192)
platform(popup,832,208,192)
platform(popup,0,688,1024,32,False)
ladder(popup,112,208,448)
ladder(popup,928,64,688)
ladder(popup,80,448,688)
platform(popup,832,64,192)
gate(popup,'fuse_a_bulkhead',496,448,240,'popup_fuse_a')
gate(popup,'lower_fuse_gate',496,688,240,'popup_fuse_a')
gate(popup,'window_loop',496,208,208,'popup_power_restored')
area(popup,'hall','故障广告大厅',[0,288,512,240],[32,448],'中层','window')
area(popup,'east','供电竖井',[512,288,512,240],[928,448],'中层','tower')
area(popup,'loft','封存缓存夹层',[0,0,512,288],[32,208],'上层','window')
area(popup,'shaft','重叠窗口保险室',[512,0,512,288],[928,208],'上层','window')
area(popup,'drain','底层缓存回路',[0,528,1024,240],[80,688],'下层','shelves')
connect(popup,'loft_ladder','hall','loft',[112,448],'↑ 缓存夹层')
connect(popup,'fuse_door','hall','east',[496,448],'→ 第二保险室','popup_fuse_a')
connect(popup,'east_ladder','east','shaft',[928,448],'↑ 供电竖井')
connect(popup,'power_loop','shaft','loft',[496,208],'← 大厅捷径','popup_power_restored')
connect(popup,'drain_ladder','hall','drain',[80,448],'↓ 缓存回路')
connect(popup,'drain_return','drain','shaft',[928,688],'↑ 返回保险室','popup_fuse_a')
popup['tutorial_zones']=[dict(id='reflector',rect=[130,310,100,160])]

recycle = merge('recycle')
platform(recycle,320,688,192,32,False)
platform(recycle,832,688,192,32,False)
platform(recycle,832,208,192)
platform(recycle,80,64,944)
ladder(recycle,448,448,688)
ladder(recycle,80,64,448)
ladder(recycle,976,64,688)
gate(recycle,'hoist_loop_lock',496,208,208,'recycle_route_repaired')
gate(recycle,'return_tunnel_lock',336,688,160,'recycle_route_repaired')
mechanism(recycle,'fragment1')['position']=[400,672]
recycle['chests'][-1]['position']=[128,688]
area(recycle,'upper_left','吊装观察台',[0,0,512,288],[80,64],'上层','crane')
area(recycle,'cache','数据重构吊台',[512,0,512,288],[928,208],'上层','crane')
area(recycle,'sorter','中央分拣大厅',[0,288,512,240],[32,448],'中层','ring')
area(recycle,'maintenance','侧面维护竖井',[832,288,192,480],[976,688],'竖井','tower')
area(recycle,'scrap','地下废料坑',[352,528,160,240],[448,688],'下层','shelves')
area(recycle,'well','磁吸拆解井',[512,528,320,240],[560,688],'下层','crane')
area(recycle,'tunnel','回访磁吸暗道',[0,528,352,240],[304,688],'下层','shelves')
connect(recycle,'observation','sorter','upper_left',[80,448],'↑ 吊装观察台')
connect(recycle,'scrap_drop','sorter','scrap',[448,448],'↓ 废料坑 / 磁吸井')
connect(recycle,'well_entry','scrap','well',[512,688],'→ 磁吸井')
connect(recycle,'service_gate','well','maintenance',[792,688],'→ 维修井','recycle_heavy_supported')
connect(recycle,'service_ladder','maintenance','cache',[976,688],'↑ 重构吊台')
connect(recycle,'hoist_loop','cache','upper_left',[496,64],'← 分拣大厅捷径','recycle_route_repaired')
connect(recycle,'hidden_return','scrap','tunnel',[336,688],'← 回访暗道','recycle_route_repaired')
recycle['signs'] += [[370,630,'通信碎片 1 / 3'],[594,564,'抬起 → 右移 → 放下'],[710,650,'击碎吊下的废料板'],[700,174,'三片数据 → 重构']]
recycle['tutorial_zones']=[dict(id='conveyor',rect=[48,386,90,80]),dict(id='magnet',rect=[640,600,100,110])]

signal = merge('signal', (1024,768))
platform(signal,800,448,224,32,False)
platform(signal,0,208,704)
platform(signal,0,688,1024,32,False)
ladder(signal,112,208,448)
ladder(signal,80,448,688)
ladder(signal,976,64,688)
platform(signal,920,64,104)
gate(signal,'upper_bus_loop',336,208,208,'signal_core_ready')
gate(signal,'lower_bus_loop',800,688,192,'signal_shortcut')
signal['mechanisms'].append(dict(id='local_a',type='repair',position=[112,208],requires_all=['signal_archive_gate'],outputs=['signal_local_a'],label='校准 A 支路 · 读取档案真实重量',locked_hint='A 需要 ARCHIVE 的重石持续压住压板。',success='本地 A 已校准 · 源信号仍按真实重量读取'))
mechanism(signal,'relay_shortcut')['requires_all']=['signal_bee_charged','popup_power_restored']
mechanism(signal,'relay_shortcut')['outputs']=['signal_shortcut','signal_local_b']
align=mechanism(signal,'fiber_align')
align.update(type='repair',requires_all=['message_packet_restored'],outputs=['signal_optics_aligned','signal_local_c'],success='本地 C 已校准 · 固定通信数据接入光纤')
mechanism(signal,'signal_repair')['requires_all'] += ['signal_local_a','signal_local_b','signal_local_c']
area(signal,'hub','三路中央诊断台',[0,288,320,240],[96,448],'中层','tower')
area(signal,'a','A 真实源信号塔',[0,0,352,288],[112,208],'上层','tower')
area(signal,'relay','B 继电蜂桥',[320,288,480,240],[352,448],'中层','tower')
area(signal,'fiber','C 光纤汇流井',[704,0,320,288],[976,208],'上层','tower')
area(signal,'return','侧面光纤干道',[800,288,224,240],[976,448],'竖井','tower')
area(signal,'water','绝缘水道旁路',[0,528,1024,240],[80,688],'下层','crane')
connect(signal,'a_branch','hub','a',[112,448],'↑ A 真实源')
connect(signal,'b_branch','hub','relay',[320,448],'→ B 继电蜂桥')
connect(signal,'c_branch','return','fiber',[976,448],'↑ C 光纤汇流')
connect(signal,'bus_loop','fiber','a',[336,208],'← 诊断台捷径','signal_core_ready')
connect(signal,'water_branch','hub','water',[80,448],'↓ 绝缘水道')
connect(signal,'water_return','water','return',[800,688],'→ 保存旁路','signal_shortcut')
signal['tutorial_zones']=[dict(id='relay',rect=[430,310,180,170])]

error = merge('error')
platform(error,480,448,32,32,False)
platform(error,992,448,32,32,False)
platform(error,0,208,704)
platform(error,0,688,352,32,False)
platform(error,672,688,352,32,False)
platform(error,64,64,960)
ladder(error,80,64,688)
ladder(error,976,64,688)
gate(error,'foyer_bulkhead',496,448,240,'error_foyer_open')
gate(error,'core_authority_gate',688,688,192,'error_diagnostic_cleared')
gate(error,'core_a_return',336,688,192,'error_node_a')
gate(error,'core_b_upper_return',496,64,64,'error_node_b')
mechanism(error,'core_authorize')['requires_all'].append('error_piston_supported')
area(error,'foyer','蓝屏前厅',[0,288,512,240],[32,448],'中层','core')
area(error,'piston','活塞故障线',[512,288,512,240],[552,448],'中层','crane')
area(error,'observation','核心观察环',[0,0,704,288],[80,208],'上层','core')
area(error,'diagnostic','核心诊断站',[704,0,320,288],[976,208],'上层','tower')
area(error,'west','A 返回维护道',[0,528,352,240],[80,688],'下层','shelves')
area(error,'boss','蓝屏核心室',[352,528,336,240],[656,688],'下层','core')
area(error,'east','核心安全入口',[688,528,336,240],[976,688],'下层','shelves')
connect(error,'outer_piston','foyer','piston',[496,448],'→ 活塞故障线','error_foyer_open')
connect(error,'diagnostic_ladder','piston','diagnostic',[976,448],'↑ 核心诊断站')
connect(error,'core_entry','east','boss',[688,688],'← 核心 A → B → C','error_diagnostic_cleared')
connect(error,'a_loop','boss','west',[336,688],'← A 返回前厅','error_node_a')
connect(error,'outer_ladder','foyer','observation',[80,448],'↑ 核心观察环')
connect(error,'b_loop','observation','diagnostic',[496,64],'→ B 上层回环','error_node_b')

for name, d in [('boot',boot),('archive',archive),('popup',popup),('recycle',recycle),('signal',signal),('error',error)]:
    # Nearby fork directions share one board rather than drawing over one another.
    boards=[]
    for c in d['connections']:
        x,y=c['position']
        board=next((b for b in boards if abs(b[0]-x)<150 and abs(b[1]-y)<32),None)
        if board is None:
            board=[x,y,[]];boards.append(board)
        board[2].append(c['label'])
    for x,y,labels in boards:
        for i,text in enumerate(labels): d['signs'].append([max(8,x-38),max(14,y-30-14*(len(labels)-1)+i*14),text])
    write(ROOT/f'data/levels/{name}_01.json',d)

links=read(LEGACY/'screen_links.json')
names={'BOOT':'boot','ARCHIVE':'archive','POP-UP':'popup','RECYCLE':'recycle','SIGNAL':'signal','ERROR':'error'}
for link in links:
    source=names[link['from']]
    old_room=link.get('room') or 'main'
    offset=OFFSETS[source].get(old_room,[0,0])
    link['position']=shifted(link['position'],offset)
    link['room']=''
write(ROOT/'data/screen_links.json',links)

# Evidence diagrams use the same graph data as runtime navigation.
lines=['# 六关拓扑对照（布局 v2）','',
       '旧：BOOT/ARCHIVE 横向一层；后四关通过 E 端口逐间切换。',
       '新：每关一个连续物理空间；下列每条边均为可步行或攀爬的双向连接。跨 CRT 端口另行保留。','']
for name in ('boot','archive','popup','recycle','signal','error'):
    d=read(ROOT/f'data/levels/{name}_01.json')
    lines += [f'## {name.upper()} · {d["size"][0]} × {d["size"][1]}','', '```mermaid','flowchart TD']
    for a in d['areas']: lines.append(f'  {a["id"]}["{a["name"]} / {a["floor"]}"]')
    for c in d['connections']:
        text=c['label']+(' · '+c['requires'] if c['requires'] else '')
        lines.append(f'  {c["from"]} <-->|"{text}"| {c["to"]}')
    lines += ['```','']
(ROOT/'docs/design/TOPOLOGY.md').write_text('\n'.join(lines),encoding='utf-8')
print('Authored six continuous worlds, migrated port coordinates, and shared topology diagrams.')
