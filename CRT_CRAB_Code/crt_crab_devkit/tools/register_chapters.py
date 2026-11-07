"""Register completed chapters without touching physical CRT transforms or old routes."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(path): return json.loads((ROOT/path).read_text(encoding='utf-8'))
def write(path,data): (ROOT/path).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
manifest=read('data/screen_manifest.json')
layout=read('data/monitor_layout.json')
links=read('data/screen_links.json')
for id,slug,index,name,color in [('POP-UP','popup',4,'弹窗区','e7a0c0'),('RECYCLE','recycle',6,'回收站','b4cc8c'),('SIGNAL','signal',9,'信号中心','74cbd0'),('ERROR','error',11,'错误核心','aaa2e0')]:
    implemented=(ROOT/f'data/levels/{slug}_01.json').exists()
    manifest[id]=dict(name=name,computer_id=layout[index]['computer_id'],level_id=slug+'_01',definition=f'res://data/levels/{slug}_01.json',color=color,implemented=implemented)
    layout[index]['screen']=id
if not any(l['id']=='archive_popup' for l in links):
    links.append(dict(id='archive_popup',**{'from':'ARCHIVE'},to='POP-UP',source_computer_id='crt_archive_05',target_computer_id='crt_sleep_04',spawn_id='entrance',position=[704,208],requires='archive_key',label='前往 POP-UP 修复供电',locked_hint='先取得档案密钥。'))
if not any(l['id']=='popup_archive' for l in links):
    links.append(dict(id='popup_archive',**{'from':'POP-UP'},room='hall',to='ARCHIVE',source_computer_id='crt_sleep_04',target_computer_id='crt_archive_05',spawn_id='return',position=[32,208],requires='',label='回访 ARCHIVE',locked_hint=''))
for id,source,target,source_room,position,requirement,label in [('popup_recycle','POP-UP','RECYCLE','shaft',[288,80],'popup_power_restored','连接 RECYCLE'),('recycle_popup','RECYCLE','POP-UP','sorter',[32,208],'','回访 POP-UP'),('recycle_signal','RECYCLE','SIGNAL','cache',[288,208],'message_packet_restored','连接 SIGNAL'),('signal_recycle','SIGNAL','RECYCLE','diagnostic',[32,208],'','回访 RECYCLE'),('signal_archive','SIGNAL','ARCHIVE','diagnostic',[64,208],'','返回 ARCHIVE 修复实时 A 输入'),('signal_error','SIGNAL','ERROR','shaft',[288,208],'signal_core_ready','连接 ERROR'),('error_signal','ERROR','SIGNAL','foyer',[32,208],'','回访 SIGNAL'),('error_archive','ERROR','ARCHIVE','diagnostic',[64,208],'','返回 ARCHIVE 修复当前输入 A')]:
    if manifest[target].get('implemented',True) and not any(l['id']==id for l in links):
        links.append(dict(id=id,**{'from':source},to=target,room=source_room,source_computer_id=manifest[source]['computer_id'],target_computer_id=manifest[target]['computer_id'],spawn_id='entrance',position=position,requires=requirement,label=label,locked_hint='先完成当前屏幕的主修复目标。'))
for id,source,target,source_room,position,spawn in [('recycle_boot','RECYCLE','BOOT','cache',[224,144],'return'),('boot_recycle','BOOT','RECYCLE','',[752,208],'entrance')]:
    if not any(l['id']==id for l in links):
        links.append(dict(id=id,**{'from':source},to=target,room=source_room,source_computer_id=manifest[source]['computer_id'],target_computer_id=manifest[target]['computer_id'],spawn_id=spawn,position=position,requires='recycle_route_repaired',label='RECYCLE 修复后的返向快捷链路',locked_hint='RECYCLE 重构数据包后，此快捷端口会通电。'))
write('data/screen_manifest.json',manifest)
write('data/monitor_layout.json',layout)
write('data/screen_links.json',links)
print('Registered chapter identities; physical transforms and existing routes preserved.')
