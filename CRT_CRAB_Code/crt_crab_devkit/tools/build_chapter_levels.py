"""Author the incremental room definitions; BOOT/ARCHIVE are never regenerated."""
import json
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]

def room(name, width=320, background='popup'):
    return dict(name=name,size=[width,240],background=background,spawns={'entrance':[32,208],'return':[width-32,208]},platforms=[[0,208,width,32]],ladders=[],blocks=[],plates=[],doors=[],chests=[],crystals=[],breakables=[],enemies=[],terminals=[],signs=[],room_portals=[],mechanisms=[],animals=[])

def portal(to, position, label, spawn='entrance', requires='', hint='先完成当前房间的机关。'):
    return dict(to=to,position=position,label=label,spawn=spawn,requires=requires,locked_hint=hint)

def save(name, entry, rooms):
    (ROOT/f'data/levels/{name}_01.json').write_text(json.dumps(dict(entry_room=entry,rooms=rooms),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

hall=room('故障广告回廊',480)
hall['spawns']['loft_return']=[112,160]
hall['platforms'] += [[80,160,64,16],[336,160,64,16]]
hall['ladders']=[dict(x=112,top=160,bottom=208)]
hall['animals']=[dict(id='popup_moth_a',species='moth',position=[64,120])]
hall['animals'].append(dict(id='popup_flea',species='flea',position=[368,160],health=1))
hall['mechanisms']=[dict(id='reflect_a',type='reflector',position=[176,120],control=[176,208],label='旋转导流片 ↑ / ↓'),dict(id='fuse_a',type='receiver',position=[176,184],flag='popup_fuse_a'),dict(id='current_a',type='hazard',position=[240,208],disabled_by='popup_fuse_a'),dict(id='fallback_a',type='pulse',position=[80,208],emitter=[64,120],direction=[1,0],label='备用测试脉冲 · 飞蛾被击败也能重试')]
hall['mechanisms'].append(dict(id='timed_popup',type='popup_panel',position=[224,208],disabled_by='popup_fuse_a'))
hall['doors']=[dict(id='popup_gate_a',position=[304,208],height=56,requires='popup_fuse_a')]
hall['room_portals']=[portal('shaft',[432,208],'进入重叠窗口竖井',requires='popup_fuse_a'),portal('loft',[112,160],'查看缓存夹层')]
hall['signs']=[[32,44,'POP-UP / ERROR SHOTS CAN REPAIR'],[136,80,'TURN MIRROR'],[214,170,'FUSE -> POWER'],[330,128,'NEXT ROOM ->']]

shaft=room('重叠窗口竖井')
shaft['platforms'] += [[32,160,80,16],[128,120,64,16],[224,80,80,16]]
shaft['ladders']=[dict(x=64,top=160,bottom=208),dict(x=160,top=120,bottom=208),dict(x=256,top=80,bottom=208)]
shaft['animals']=[dict(id='popup_moth_b',species='moth',position=[48,104])]
shaft['mechanisms']=[dict(id='reflect_b',type='reflector',position=[160,104],control=[160,208],label='旋转第二片导流镜'),dict(id='fuse_b',type='receiver',position=[160,176],flag='popup_fuse_b'),dict(id='current_b',type='hazard',position=[224,208],disabled_by='popup_fuse_b'),dict(id='fallback_b',type='pulse',position=[80,208],emitter=[48,104],direction=[1,0],label='备用测试脉冲'),dict(id='popup_repair',type='repair',position=[256,80],label='隔离噪声并恢复供电',requires_all=['popup_fuse_a','popup_fuse_b'],outputs=['popup_noise_clean','popup_power_restored'],locked_hint='先让两间房的飞蛾弹经导流镜打中保险丝。',success='弹窗噪声已清除 · RECYCLE 供电恢复，消息仍待发送')]
shaft['room_portals']=[portal('hall',[32,208],'回到广告回廊',spawn='return')]
shaft['signs']=[[24,35,'POP-UP / 02 WINDOW SHAFT'],[226,60,'REPAIR'],[128,150,'REFLECT -> FUSE']]

loft=room('缓存夹层')
loft['platforms'] += [[96,160,208,16]]
loft['ladders']=[dict(x=112,top=160,bottom=208)]
loft['chests']=[dict(id='popup_hidden',position=[272,160],crystals=3,flag='popup_hidden')]
loft['room_portals']=[portal('hall',[32,208],'返回回廊上层',spawn='loft_return')]
loft['signs']=[[32,80,'CACHE LOFT / OPTIONAL'],[144,128,'USER MESSAGE / STILL PENDING']]
loft['animals']=[dict(id='cache_tape_snail',species='snail',position=[256,208],health=3,range=32),dict(id='cache_cable_spider',species='spider',position=[176,64])]
loft['plates']=[dict(id='snail_weight',position=[240,208],weight=2,flag='popup_loft_supported')]
loft['doors']=[dict(id='snail_bonus_gate',position=[288,208],height=40,requires='popup_loft_supported')]
loft['crystals']=[dict(id='popup_snail_bonus',position=[304,192])]
loft['mechanisms']=[dict(id='spider_bridge',type='web_bridge',position=[176,128],flag='popup_wire_live')]
loft['crystals'].append(dict(id='popup_wire_bonus',position=[176,112]))
save('popup','hall',dict(hall=hall,shaft=shaft,loft=loft))

sorter=room('输送带分拣区',480,'recycle')
sorter['spawns']['return']=[432,208]
sorter['blocks']=[dict(id='sorter_metal',position=[144,200],weight=2)]
sorter['animals']=[dict(id='recycle_hamster',species='hamster',position=[208,208],range=80)]
sorter['mechanisms']=[dict(id='belt_a',type='conveyor',position=[192,208],control=[80,208],width=176,label='REVERSE · 改变输送带方向'),dict(id='press_a',type='crusher',position=[288,208],stop='safe_stop',flag='recycle_press_used'),dict(id='safe_stop',type='stop',position=[112,208],label='SAFE STOP · 停止 / 启动压机'),dict(id='roller',type='sensor',position=[264,208],flag='recycle_roller_signal'),dict(id='fragment1',type='fragment',position=[376,192],flag='recycle_part_1')]
sorter['room_portals']=[portal('well',[432,208],'进入拆解井',requires='recycle_part_1',hint='右侧有第一片固定通信数据。')]
sorter['signs']=[[24,42,'RECYCLE / 01 SORTING'],[70,156,'REVERSE / SAFE STOP'],[240,116,'GEAR HAMSTER -> SENSOR'],[344,156,'PACKET 1 / 3']]

well=room('碎桥与磁吸拆解井',320,'recycle')
well['platforms'] += [[64,128,80,16]]
well['ladders']=[dict(x=80,top=128,bottom=208)]
well['blocks']=[dict(id='recycle_metal',position=[104,120],weight=2)]
well['breakables']=[dict(id='scrap_bridge',position=[232,160])]
well['plates']=[dict(id='recycle_weight',position=[232,208],weight=2,flag='recycle_heavy_supported')]
well['doors']=[dict(id='recycle_gate',position=[280,208],height=56,requires='recycle_heavy_supported')]
well['mechanisms']=[dict(id='magnet_well',type='magnet',position=[168,96],control=[160,208],target=[232,120],range=165,label='磁吸爪：吸起 / 放下钢块'),dict(id='fragment2',type='fragment',position=[80,112],flag='recycle_part_2')]
well['room_portals']=[portal('sorter',[32,208],'回到分拣区',spawn='return'),portal('cache',[304,208],'进入缓存重构室',requires='recycle_heavy_supported'),portal('tunnel',[80,128],'下层暗道 · 修复后回访',requires='recycle_route_repaired',hint='数据包重构后，暗道端口会通电。')]
well['signs']=[[16,38,'RECYCLE / 02 MAGNET WELL'],[96,64,'LIFT -> RIGHT -> RELEASE'],[204,142,'SCRAP / J'],[198,184,'WEIGHT 2']]

cache=room('缓存重构室',320,'recycle')
cache['platforms'] += [[128,144,176,16]]
cache['ladders']=[dict(x=144,top=144,bottom=208)]
cache['mechanisms']=[dict(id='fragment3',type='fragment',position=[96,192],flag='recycle_part_3'),dict(id='assembly',type='assembly',position=[256,208],label='重构固定的 3 片通信数据',requires_all=['recycle_part_1','recycle_part_2','recycle_part_3'],outputs=['recycle_route_repaired','message_packet_restored'],locked_hint='需分拣区、磁吸井和重构室的三片通信数据。',success='数据包已重构 · SIGNAL 通电，User 消息文字恢复，尚未送达')]
cache['chests']=[dict(id='recycle_cache',position=[272,144],crystals=3,flag='recycle_cache')]
cache['room_portals']=[portal('well',[32,208],'返回拆解井',spawn='return')]
cache['signs']=[[24,40,'RECYCLE / 03 RECONSTRUCT'],[150,176,'PACKET ASSEMBLY'],[142,112,'OPTIONAL CACHE']]

tunnel=room('回访磁吸暗道',320,'recycle')
tunnel['blocks']=[dict(id='tunnel_metal',position=[144,200],weight=2)]
tunnel['mechanisms']=[dict(id='magnet_tunnel',type='magnet',position=[176,96],control=[80,208],target=[240,120],range=160,label='磁吸挪开暗道挡块')]
tunnel['doors']=[dict(id='tunnel_gate',position=[192,208],height=64,requires='recycle_roller_signal')]
tunnel['chests']=[dict(id='recycle_hidden',position=[272,208],crystals=4,flag='recycle_hidden')]
tunnel['room_portals']=[portal('well',[32,208],'回到磁吸井',spawn='entrance')]
tunnel['signs']=[[16,40,'RECYCLE / RETURN ROUTE'],[40,132,'SORTING ROLLER OPENS THIS GATE']]
tunnel['breakables']=[dict(id='scrap_tunnel',position=[128,200])]
tunnel['animals']=[dict(id='tunnel_beaver',species='beaver',position=[112,208],health=3,range=32,breaks='scrap_tunnel')]
save('recycle','sorter',dict(sorter=sorter,well=well,cache=cache,tunnel=tunnel))

diagnostic=room('三路诊断台',320,'signal')
diagnostic['mechanisms']=[dict(id='abc_panel',type='diagnostic',position=[24,152])]
diagnostic['room_portals']=[portal('relay',[288,208],'进入继电蜂通道')]
diagnostic['signs']=[[24,42,'SIGNAL / 01 THREE REAL INPUTS'],[24,178,'A = LIVE STONE / B,C = REPAIRED']]

relay=room('继电蜂接线通道',480,'signal')
relay['platforms']=[[0,208,144,32],[144,224,160,16],[304,208,176,32],[176,176,64,16]]
relay['ladders']=[dict(x=208,top=176,bottom=224)]
relay['animals']=[dict(id='signal_bee',species='bee',position=[144,120],path=[[144,120],[256,120],[256,160],[144,160]])]
relay['animals'].append(dict(id='signal_eel',species='eel',position=[224,222],health=3,range=40,flag='signal_eel_coil'))
relay['doors']=[dict(id='relay_bridge_gate',position=[272,224],height=64,requires='signal_bee_live')]
relay['mechanisms']=[dict(id='bee_terminal',type='relay',position=[256,120],flag='signal_bee_live',charge_flag='signal_bee_charged',temporary=True,bypass='signal_shortcut'),dict(id='trough',type='hazard',position=[208,224],disabled_by='signal_water_safe'),dict(id='insulation',type='insulator',position=[112,208],flag='signal_water_safe',label='引流到绝缘水道 / 恢复'),dict(id='relay_shortcut',type='repair',position=[352,208],requires_all=['signal_bee_charged'],outputs=['signal_shortcut'],label='锁定回访旁路',success='旁路已保存 · 蜜蜂离开节点后也能安全返回')]
relay['room_portals']=[portal('diagnostic',[32,208],'查看三路输入'),portal('shaft',[432,208],'进入光纤塔井',requires='signal_bee_charged',hint='等蜜蜂停在青色节点，让缺口电路短时接通。')]
relay['signs']=[[24,40,'SIGNAL / 02 RELAY BEE'],[180,78,'BEE = MOVING WIRE'],[172,152,'INSULATED LEDGE'],[326,170,'SAVE BYPASS']]

fiber=room('三层光纤塔井',320,'signal')
fiber['platforms'] += [[24,160,72,16],[120,112,72,16],[216,64,88,16]]
fiber['ladders']=[dict(x=48,top=160,bottom=208),dict(x=144,top=112,bottom=208),dict(x=240,top=64,bottom=208)]
fiber['mechanisms']=[dict(id='fiber_align',type='insulator',position=[144,112],flag='signal_optics_aligned',label='接合第二层光纤插口'),dict(id='signal_repair',type='repair',position=[240,64],circuit=True,requires_all=['signal_bee_charged','signal_optics_aligned'],outputs=['signal_core_ready'],label='接通总线 · 发送通道 READY',locked_hint='先让蜜蜂给节点充电，再接合第二层光纤。',success='发送线路 READY · 最后的 ERROR 核心仍锁定发送权限')]
fiber['chests']=[dict(id='signal_cache',position=[288,64],crystals=3,flag='signal_cache')]
fiber['room_portals']=[portal('relay',[32,208],'回到继电蜂通道',spawn='return'),portal('diagnostic',[80,160],'快速回到三路诊断台')]
fiber['signs']=[[20,40,'SIGNAL / 03 FIBER WELL'],[120,80,'ALIGN FIBER'],[222,32,'CHANNEL READY']]
save('signal','diagnostic',dict(diagnostic=diagnostic,relay=relay,shaft=fiber))

foyer=room('蓝屏前厅',480,'error')
foyer['platforms'] += [[96,160,64,16]]
foyer['ladders']=[dict(x=112,top=160,bottom=208)]
foyer['animals']=[dict(id='error_owl',species='owl',position=[240,80],health=4)]
foyer['mechanisms']=[dict(id='owl_panel',type='break_panel',position=[256,208],flag='error_foyer_open')]
foyer['doors']=[dict(id='foyer_gate',position=[336,208],height=56,requires='error_foyer_open')]
foyer['chests']=[dict(id='error_cache',position=[144,160],crystals=4,flag='error_cache')]
foyer['room_portals']=[portal('piston',[432,208],'进入故障活塞走廊',requires='error_foyer_open',hint='引猫头鹰俯冲到裂纹板，或用 J 拆掉板件。')]
foyer['signs']=[[16,40,'ERROR / 01 OWL FOYER'],[192,128,'LURE DIVE -> SCRAP'],[98,128,'OPTIONAL CACHE']]

piston=room('故障活塞走廊',480,'error')
piston['blocks']=[dict(id='error_steel',position=[176,200],weight=2)]
piston['plates']=[dict(id='error_piston_plate',position=[272,208],weight=2,flag='error_piston_supported')]
piston['doors']=[dict(id='error_piston_gate',position=[336,208],height=56,requires='error_piston_supported')]
piston['mechanisms']=[dict(id='error_press_a',type='crusher',position=[240,208],stop='error_press_stop'),dict(id='error_press_b',type='crusher',position=[304,208],stop='error_press_stop',offset=1.3),dict(id='error_press_stop',type='stop',position=[112,208],label='活塞安全停止 / 重新启动')]
piston['room_portals']=[portal('foyer',[32,208],'回到蓝屏前厅',spawn='return'),portal('diagnostic',[432,208],'核心诊断层',requires='error_piston_supported')]
piston['signs']=[[24,40,'ERROR / 02 PISTON CORRIDOR'],[110,150,'SAFE STOP'],[242,128,'STEEL -> WEIGHT 2']]

core_diagnostic=room('核心诊断层',320,'error')
core_diagnostic['mechanisms']=[dict(id='final_diagnostic',type='diagnostic',position=[24,144]),dict(id='core_authorize',type='repair',position=[224,208],circuit=True,requires_all=['signal_core_ready'],outputs=['error_diagnostic_cleared'],label='确认真实线路，进入核心',locked_hint='发送通道尚未就绪，返回 SIGNAL 检查。',success='必要链路当前有效 · 核心隔离程序等待修复')]
core_diagnostic['room_portals']=[portal('piston',[32,208],'回到活塞走廊',spawn='return'),portal('boss',[288,208],'进入 BSOD CICADA 核心室',requires='error_diagnostic_cleared')]
core_diagnostic['signs']=[[24,40,'ERROR / 03 LIVE DIAGNOSTIC']]

boss=room('蓝屏核心 · 故障机蝉',320,'error')
boss['platforms'] += [[0,160,64,16],[256,160,64,16]]
boss['ladders']=[dict(x=32,top=160,bottom=208),dict(x=288,top=160,bottom=208)]
boss['blocks']=[dict(id='boss_steel',position=[64,200],weight=2)]
boss['plates']=[dict(id='boss_weight',position=[128,208],weight=2,flag='boss_weight_supported')]
boss['mechanisms']=[dict(id='boss_reflector',type='reflector',position=[176,120],control=[176,208],label='核心导流镜：把弹引向下方节点 B')]
boss['room_portals']=[portal('diagnostic',[16,208],'安全返回诊断层')]
boss['signs']=[[16,28,'ERROR / 04 CORE'],[10,142,'INSULATED'],[242,142,'INSULATED']]
boss['boss']={}
save('error','foyer',dict(foyer=foyer,piston=piston,diagnostic=core_diagnostic,boss=boss))

# Original low-resolution room backdrops. Geometry/actors remain live nodes.
for name,base,accent in [('popup','#282338','#69516d'),('recycle','#242d32','#6a7d6c'),('signal','#192e38','#527d85'),('error','#242337','#655c8a')]:
    im=Image.new('RGB',(768,256),base);d=ImageDraw.Draw(im)
    for x in range(16,768,64):
        d.rectangle((x,24,x+44,194),outline=accent)
        for y in range(40,192,24):
            d.line((x+6,y,x+35,y),fill=accent)
            d.rectangle((x+6,y+5,x+9,y+8),fill='#54a69c')
    for y in (16,204,232): d.line((0,y,768,y),fill=accent)
    d.text((20,7),name.upper()+' / LINK REPAIR',fill='#9fb9b4')
    im.save(ROOT/f'assets/pixel/background_{name}.png')
print('Authored chapter rooms and original pixel backdrops.')
