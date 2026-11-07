"""Original CRT standby art -> deterministic 24 fps unlock strips (no extra viewport)."""
from pathlib import Path
from math import sin, pi
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/pixel/unlock_frames'
OUT.mkdir(parents=True, exist_ok=True)
BG = '#141f2b'
GREEN = '#54cfc3'
STEPS = 37


def frame(index, t):
    source = Image.open(ROOT / f'assets/pixel/standby_{index}.png').convert('RGB')
    if t == 0:
        return source
    im = source.copy()
    d = ImageDraw.Draw(im)
    kind = index % 6
    color = ['#54cfc3', '#dce65b', '#c0a0d5', '#ea5985'][index % 4]
    # Preserve the actual title, frame and port identity. Only animate its pictogram.
    d.rectangle((19, 45, 235, 154), fill=BG)
    q = min(t / .85, 1)
    if kind == 5:
        lift = round(10 * min(q / .45, 1) + 2 * sin(min(q / .45, 1) * pi))
        fall = round(13 * max(0, (q - .5) / .5))
        d.arc((106, 65-lift, 150, 113-lift), 180, 360, fill=GREEN if q > .25 else '#8ea39c', width=4)
        d.line((108, 87-lift, 108, 96-lift), fill=GREEN, width=4)
        d.rectangle((103, 88+fall, 153, 128+fall), fill='#405563', outline=GREEN if q > .25 else color, width=2)
        d.rectangle((126, 101+fall, 130, 116+fall), fill=GREEN if q > .15 else color)
    elif kind == 3:
        for k, y in enumerate(range(64, 128, 8)):
            p = min(1, max(0, (q-k*.055)/.45))
            left = round((20+(y*7) % 30)*(1-p)+24*p)
            right = round((224-(y*3) % 48)*(1-p)+230*p)
            d.line((left, y, right, y), fill=GREEN if p == 1 else color, width=2)
        d.text((84, 138), 'SIGNAL STABLE' if q > .8 else 'RECONNECT', fill=GREEN)
    elif kind == 1:
        nodes = [(60,80), (128,118), (200,70)]
        for k, (a,b) in enumerate(zip(nodes, nodes[1:])):
            p = min(1, max(0, (q-.14-k*.3)/.3))
            d.line((*a,*b), fill='#5c777c', width=2)
            end = (round(a[0]+(b[0]-a[0])*p),round(a[1]+(b[1]-a[1])*p))
            if p > 0: d.line((*a,*end), fill=GREEN, width=3)
        for k,(x,y) in enumerate(nodes):
            lit = q > k*.3
            d.rectangle((x-10,y-8,x+10,y+8),outline=GREEN if lit else color,width=2)
            if lit: d.rectangle((x-4,y-3,x+4,y+3), fill=GREEN)
        d.text((35,96),'BOOT',fill=color)
        d.text((175,88),'ARCHIVE',fill='#a9a2c0')
    elif kind == 4:
        d.ellipse((95,60,159,124),fill=color)
        d.ellipse((109,51,169,114),fill=BG)
        d.arc((95,60,159,124), -90, -90+round(360*q), fill=GREEN,width=3)
        for k,(x,y) in enumerate([(52,70),(191,88),(70,124)]):
            d.rectangle((x,y,x+3,y+3),fill=GREEN if q > k*.25 else '#9fb2b3')
            if q > .55: d.line((x+1,y+1,126,92),fill='#365b60')
        if q == 1:
            d.ellipse((95,60,159,124), fill=BG, outline=GREEN, width=3)
            d.line((127,73,127,100),fill=GREEN,width=4)
    elif kind == 2:
        for k,(x,y) in enumerate([(36,60),(100,78),(164,96)]):
            p = min(1,max(0,(q-k*.22)/.35))
            d.rectangle((x,y,x+50,y+34),fill='#354354',outline=GREEN if p == 1 else '#91a3a8')
            d.rectangle((x+9,y+9,x+9+round(31*p),y+12),fill=GREEN if p == 1 else color)
            d.rectangle((x+9,y+18,x+30,y+20),fill='#83959b')
    else:
        for k,y in enumerate(range(56,144,12)):
            p = min(1,max(0,(q-(7-k)*.055)/.45))
            end = round((70+((y+index)*7)%130)*(1-p)+218*p)
            d.line((24,y,end,y),fill=GREEN if p == 1 else '#4e7d7a')
        d.rectangle((224,130,233,138),fill=GREEN if q > .85 else color)
    if t >= .85:
        labels = ['LINK OK','NODES ONLINE','DATA VERIFIED','SIGNAL STABLE','WAKE UP / READY','PORT UNLOCKED']
        d.rectangle((20,141,235,154),fill=BG)
        d.text((24,143),labels[kind],fill=GREEN)
    return im


for index in range(12):
    strip = Image.new('RGB',(256*8,192*5),BG)
    for n in range(STEPS): strip.paste(frame(index,n/(STEPS-1)),((n%8)*256,(n//8)*192))
    strip.save(OUT / f'unlock_{index}.png', optimize=True)
print('Generated twelve standby-derived unlock strips, 37 frames each.')
