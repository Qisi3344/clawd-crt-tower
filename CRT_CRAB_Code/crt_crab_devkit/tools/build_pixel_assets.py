"""Original, deterministic pixel atlas. Pillow is an authoring tool, not a game dependency."""
from pathlib import Path
from PIL import Image, ImageDraw
import math

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'pixel'
OUT.mkdir(parents=True, exist_ok=True)
atlas = Image.new('RGBA', (256, 544))
INK = '#152130'

for row in range(17):
    for frame in range(8):
        im = Image.new('RGBA', (32, 32))
        d = ImageDraw.Draw(im)
        if row <= 5:
            bob = (frame % 4 in (1, 3)) if row in (1, 4) else 0
            y = 10 - int(bob)
            d.rectangle((7,y,24,y+12), fill=INK)
            d.rectangle((8,y+1,23,y+11), fill='#d97757')
            d.rectangle((9,y+1,22,y+2), fill='#f4aa76')
            d.rectangle((9,y+10,22,y+11), fill='#a9513f')
            for i,x in enumerate((9,13,18,22)):
                lift = 2 if row in (1,4) and (i+frame)%2 else 0
                d.rectangle((x,23-lift,x+1,27-lift),fill=INK)
                d.rectangle((x,23-lift,x+1,25-lift),fill='#c9694b')
            for x in (3,25):
                arm_y = y+5
                reach = 2 if row==3 else 0
                xx = x+reach if x==25 else x
                d.rectangle((xx,arm_y,xx+3,arm_y+5),fill=INK)
                d.rectangle((xx,arm_y+1,xx+3,arm_y+3),fill='#e18c62')
                d.point((xx+1,arm_y),fill='#f5b486')
            for x in (12,19):
                if row==5:
                    d.line((x,y+4,x+1,y+6),fill=INK)
                    d.line((x+1,y+4,x,y+6),fill=INK)
                else:
                    d.rectangle((x,y+4,x+1,y+7),fill='#27304b')
                    d.point((x,y+4),fill='#fff3d4')
            if row==3:
                d.arc((22,6,31,24),-70,75,fill='#f7e6aa',width=2)
        elif row in (6,7):
            d.rectangle((5,13,26,27),fill=INK)
            d.rectangle((6,14,25,26),fill='#ae7650')
            d.rectangle((7,16,24,24),fill='#5d484c')
            for x in (8,22):d.rectangle((x,14,x+2,26),fill='#e6c76d')
            d.rectangle((5,11 if row==6 else 5,26,16 if row==6 else 10),fill=INK)
            d.rectangle((6,12 if row==6 else 6,25,14 if row==6 else 8),fill='#efcc74')
            d.rectangle((14,16,17,20),fill='#e6c76d')
            if row==7:d.rectangle((8,12,23,14),fill='#172b33')
        elif row==8:
            y=16-(frame%2)
            for x in (7,12,19,24):d.line((x,y+5,x+(1 if frame%2 else -1),y+8),fill='#b56eb5')
            d.rectangle((6,y-6,25,y+5),fill=INK)
            d.rectangle((8,y-7,22,y+3),fill='#9b68b2')
            d.rectangle((9,y-6,20,y-4),fill='#d49bda')
            d.rectangle((10,y-1,12,y+1),fill='#f8de72')
            d.rectangle((20,y-1,22,y+1),fill='#f8de72')
        elif row in (9,10):
            if row==9:
                d.rectangle((8,8,23,23),fill=INK)
                d.rectangle((9,9,22,22),fill='#c8965d')
                d.rectangle((10,10,21,11),fill='#f1cf85')
                d.line((10,12,20,21),fill='#795246',width=2)
                d.line((20,12,10,21),fill='#795246',width=2)
                for x,y in ((10,10),(21,10),(10,21),(21,21)):d.point((x,y),fill='#f3d990')
            else:
                d.polygon([(11,8),(21,8),(24,12),(24,21),(20,24),(10,23),(7,19),(8,12)],fill=INK)
                d.polygon([(12,9),(20,9),(23,13),(22,20),(19,23),(11,21),(9,18),(10,12)],fill='#8d9aa5')
                d.line((12,10,19,10,21,13),fill='#c7d3d2',width=2)
                d.line((17,14,14,17,17,21),fill='#526473')
                d.point((12,14),fill='#e1cb73')
        elif row==11:
            d.rectangle((4,22,27,27),fill=INK)
            d.rectangle((6,22 if frame==0 else 25,25,25 if frame==0 else 27),fill='#dce65b' if frame else '#7c8e85')
            for x in (7,23):d.point((x,27),fill='#e2f0c4')
        elif row==12:
            d.rectangle((8,0,23,31),fill=INK)
            d.rectangle((10,0,21,31),fill='#63747c')
            for y in range(2,32,5):
                d.rectangle((11,y,20,y+2),fill='#8e9e9b')
                d.point((10,y),fill='#b2c3bb')
            d.rectangle((14,0,16,31),fill='#344553')
        elif row==13:
            d.rectangle((7,5,24,29),fill=INK)
            d.rectangle((8,6,23,27),fill='#526877')
            d.rectangle((10,8,21,18),fill='#102c35')
            d.line((12,13,14,15,19,10),fill='#dce65b',width=2)
            d.rectangle((11,22,20,23),fill='#54cfc3')
        elif row==14:
            for x in (10,21):d.rectangle((x,0,x+1,31),fill='#7799a5')
            for y in range(3,32,8):d.rectangle((11,y,21,y+1),fill='#bfd4c7')
        elif row==15:
            y=16+int(math.sin(frame/8*math.tau)*2)
            d.polygon([(16,y-7),(21,y),(16,y+7),(11,y)],fill=INK)
            d.polygon([(16,y-5),(19,y),(16,y+4),(13,y)],fill='#54cfc3')
            d.line((16,y-4,14,y),fill='#d8f5c5')
        elif row==16:
            d.rectangle((7,7,24,24),fill=INK)
            d.rectangle((8,8,23,23),fill='#78617b')
            d.line((10,9,18,15,14,20,19,22),fill='#d9b6b9',width=2)
            d.point((21,10),fill='#b290a4')
        atlas.alpha_composite(im,(frame*32,row*32))
atlas.save(OUT/'sprites.png')

tiles=Image.new('RGBA',(128,32))
d=ImageDraw.Draw(tiles)
for row in range(2):
    for col in range(8):
        x,y=col*16,row*16
        base='#354e5b' if row==0 else '#4d465b'
        d.rectangle((x,y,x+15,y+15),fill=base)
        d.line((x,y,x+15,y),fill='#72a4a1' if row==0 else '#9c88af')
        d.line((x,y+15,x+15,y+15),fill='#1b2938')
        d.line((x+15,y+1,x+15,y+14),fill='#263443')
        d.rectangle((x+3,y+5,x+11,y+6),fill='#293b4c' if row==0 else '#373344')
        for xx,yy in ((2,2),(13,13)):d.point((x+xx,y+yy),fill='#9eafad')
tiles.save(OUT/'tiles.png')

for name,base,accent in [('boot','#122b37','#365760'),('archive','#272638','#4b405d')]:
    bg=Image.new('RGB',(768,256),base);d=ImageDraw.Draw(bg)
    for x in range(16,768,64):
        d.rectangle((x,24,x+43,191),fill='#1b3541' if name=='boot' else '#332e45')
        d.rectangle((x+2,26,x+41,27),fill=accent)
        if name=='boot':
            for y in (44,84,124,164):
                d.rectangle((x+8,y,x+34,y+18),outline=accent)
                for xx in range(x+12,x+32,7):d.point((xx,y+5),fill='#54777a')
        else:
            for y in range(40,181,24):
                d.line((x+4,y+18,x+39,y+18),fill=accent)
                for k in range(5):
                    colors=['#584b6c','#706078','#485467','#85766d']
                    d.rectangle((x+5+k*7,y+2+(k%3)*2,x+9+k*7,y+17),fill=colors[(k+x//64)%4])
    for y in (16,196,232):
        d.line((0,y,768,y),fill=accent)
        d.line((0,y+2,768,y+2),fill='#0f202d')
    d.text((22,8), 'BOOT / WEIGHT = SIGNAL' if name=='boot' else 'ARCHIVE / KEEP THE STONE ON THE PLATE',fill='#73969a' if name=='boot' else '#a18daf')
    for x in range(32,768,96):
        d.rectangle((x,201,x+26,203),fill='#547772' if name=='boot' else '#725f7c')
    bg.save(OUT/f'background_{name}.png')
print('Authored pixel atlas:',OUT)

# Original standby illustrations; labels describe display states, not fake levels.
for index in range(12):
    im=Image.new('RGB',(256,192),'#141f2b');d=ImageDraw.Draw(im)
    color=['#54cfc3','#dce65b','#c0a0d5','#ea5985'][index%4]
    d.rectangle((10,10,245,181),outline='#384958')
    names=['STANDBY','LINK MAP','MEMORY BAY','NO SIGNAL','SLEEP MODE','PORT LOCKED']
    d.text((20,20),names[index%6],fill=color)
    d.text((20,162),f'PORT_{index:02}  /  SCREEN ISLANDS',fill='#7d939d')
    kind=index%6
    if kind==0:
        for y in range(56,144,12):
            d.line((24,y,70+((y+index)*7)%130,y),fill='#4e7d7a')
        d.rectangle((184,130,193,138),fill=color)
    elif kind==1:
        for a,b in [((60,80),(128,118)),((128,118),(200,70))]:d.line((*a,*b),fill='#5c777c',width=2)
        for x,y in [(60,80),(128,118),(200,70)]:
            d.rectangle((x-10,y-8,x+10,y+8),outline=color,width=2)
        d.text((35,96),'BOOT',fill=color);d.text((175,88),'ARCHIVE',fill='#a9a2c0')
    elif kind==2:
        for x,y in [(36,60),(100,78),(164,96)]:
            d.rectangle((x,y,x+50,y+34),fill='#354354',outline='#91a3a8')
            d.rectangle((x+9,y+9,x+40,y+12),fill=color)
            d.rectangle((x+9,y+18,x+30,y+20),fill='#83959b')
    elif kind==3:
        for y in range(64,128,8):
            d.rectangle((20+(y*7)%30,y,224-(y*3)%48,y+2),fill=color if y%16 else '#506677')
        d.text((88,138),'RECONNECT',fill='#b0bca6')
    elif kind==4:
        d.ellipse((95,60,159,124),fill=color)
        d.ellipse((109,51,169,114),fill='#141f2b')
        for x,y in [(52,70),(191,88),(70,124)]:d.rectangle((x,y,x+2,y+2),fill='#9fb2b3')
    else:
        d.arc((106,65,150,113),180,360,fill='#8ea39c',width=4)
        d.rectangle((103,88,153,128),fill='#405563',outline=color,width=2)
        d.rectangle((126,101,130,116),fill=color)
    im.save(OUT/f'standby_{index}.png')
