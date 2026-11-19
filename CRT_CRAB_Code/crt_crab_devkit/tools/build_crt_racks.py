"""Build the two gallery racks from Kenney CC0 sources and original low-poly geometry."""
import json
import math
import struct
from functools import lru_cache
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/environment/crt_rack'
SOURCE = ROOT / 'assets/environment/originals/furniture-kit'
WHITE_UV = (0.94, 0.76)
TAU = math.tau


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def mul(a, k):
    return tuple(x * k for x in a)


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def normalize(v):
    return mul(v, 1 / max(math.sqrt(sum(x*x for x in v)), 1e-10))


def slot_uv(slot, u, v):
    return ((128*(slot%4)+2+124*u)/512, (128*(slot//4)+2+124*v)/256)


def make_atlas():
    atlas = Image.new('RGBA', (512, 256), (255, 255, 255, 0))
    font = ImageFont.load_default(size=11)
    for slot in range(7):
        cell = Image.new('RGBA', (128, 128), (16, 29, 35, 32))
        d = ImageDraw.Draw(cell)
        ink = [(135,197,180,224),(202,163,96,222),(112,175,175,223),
               (128,183,125,218),(170,156,180,216),(117,171,194,220)][slot%6]
        dim = (46,79,78,105)
        if slot == 6:
            d.rectangle((0,0,127,127), fill=(182,177,149,0))
            d.rectangle((4,4,123,123), outline=(73,70,62,0),width=4)
            d.text((12,15),'VIDEO LAB',font=ImageFont.load_default(size=20),fill=(48,55,55,0))
            d.line((12,47,116,47),fill=(73,70,62,0),width=3)
            d.text((12,53),'SERVICE  09',font=font,fill=(48,55,55,0))
            for x in range(13,108,4):
                d.rectangle((x,79,x+(x%3),105),fill=(60,57,54,0))
        else:
            d.rounded_rectangle((2,2,125,125),radius=14,fill=(19,36,42,44))
            titles = ['BARS   75%', 'SCOPE  A', 'PPI    02', 'MEM TEST', 'LINE  04', 'SYNC  50']
            d.text((10,10),titles[slot],font=font,fill=ink)
            d.line((10,25,117,25),fill=dim)
            if slot==0:
                for i,col in enumerate(['b5bab0','b2a862','73a9a8','77997a','a77c96','a46d70','616988']):
                    rgb=bytes.fromhex(col)
                    d.rectangle((9+16*i,34,24+16*i,84),fill=(*rgb,217))
                    d.rectangle((9+16*i,86,24+16*i,95),fill=tuple(int(c*.51) for c in rgb)+(165,))
                d.text((10,101),'CH 03   NTSC',font=font,fill=ink)
            elif slot in (1,5):
                for i in range(17,119,15):
                    d.line((i,33,i,99),fill=dim)
                    if i<79: d.line((9,i+21,117,i+21),fill=dim)
                pts=[(x,66+int(17*math.sin(x*.097)+9*math.sin(x*.23))) for x in range(9,118)]
                d.line(pts,fill=ink,width=3)
                d.text((10,103),'1.0V / DIV',font=font,fill=ink)
            elif slot==2:
                for r in (13,26,38):
                    d.ellipse((63-r,70-r,63+r,70+r),outline=dim,width=2)
                d.line((22,70,104,70),fill=dim); d.line((63,30,63,110),fill=dim)
                d.line((63,70,91,44),fill=ink,width=3)
                for x,y in [(72,59),(82,65),(47,87)]:
                    d.rectangle((x,y,x+3,y+2),fill=ink)
            elif slot==3:
                for i,txt in enumerate(['RAM  64K  OK','ROM  02A0','VIDEO     OK','> READY_']):
                    d.text((10,34+i*18),txt,font=font,fill=ink)
            else:
                for i in range(5):
                    x=14+i*21
                    d.rectangle((x,86-i*8,x+11,91),fill=ink)
                d.text((13,101),'LEVEL / dB',font=font,fill=ink)
            for y in range(4,124,4):
                for x in range(5,123):
                    r,g,b,a=cell.getpixel((x,y))
                    cell.putpixel((x,y),(int(r*.91),int(g*.91),int(b*.91),a))
        atlas.paste(cell,((slot%4)*128,(slot//4)*128))
    atlas.convert('RGB').save(OUT/'service_displays.png')


@lru_cache(maxsize=2)
def kenney(name):
    data=(SOURCE/(name+'.glb')).read_bytes()
    n=struct.unpack_from('<I',data,12)[0]
    document=json.loads(data[20:20+n])
    binary=data[28+n:]
    def accessor(index):
        a=document['accessors'][index]; view=document['bufferViews'][a['bufferView']]
        fmt='<'+{5126:'f',5123:'H',5125:'I'}[a['componentType']]*{'SCALAR':1,'VEC3':3}[a['type']]
        start=view.get('byteOffset',0)+a.get('byteOffset',0)
        stride=view.get('byteStride',struct.calcsize(fmt))
        return [struct.unpack_from(fmt,binary,start+i*stride) for i in range(a['count'])]
    parts=[]
    for p in document['meshes'][0]['primitives']:
        positions=accessor(p['attributes']['POSITION'])
        normals=accessor(p['attributes']['NORMAL'])
        ids=[v[0] for v in accessor(p['indices'])]
        parts.append((document['materials'][p['material']]['name'],positions,normals,ids))
    return parts


def rounded(w,h,r):
    r=min(r,w*.46,h*.46)
    return [(sx*(w/2-r)+r*math.cos((i+j/3)*math.pi/2),
             sy*(h/2-r)+r*math.sin((i+j/3)*math.pi/2))
            for i,(sx,sy) in enumerate([(1,1),(-1,1),(-1,-1),(1,-1)]) for j in range(4)]


class Rack:
    def __init__(self):
        self.tris=[]
        self.base=(0,0,0)
        self.ao_boxes=[]

    def triangle(self, a,b,c, paint, uvs=None, normals=None):
        n=normalize(cross(sub(b,a),sub(c,a)))
        if n==(0,0,0): return
        for p,uv,norm in zip((a,b,c),uvs or [WHITE_UV]*3,normals or [n]*3):
            self.tris.append((add(p,self.base),norm,paint,uv))

    def quad(self,a,b,c,d,paint):
        self.triangle(a,b,c,paint); self.triangle(a,c,d,paint)

    def loft(self,center,profiles,colors):
        rings=[]
        for w,h,r,z in profiles:
            rings.append([add(center,(x,y,z)) for x,y in rounded(w,h,r)])
        for j,(a,b) in enumerate(zip(rings,rings[1:])):
            for i in range(len(a)):
                k=(i+1)%len(a)
                self.quad(a[i],a[k],b[k],b[i],colors[j])
        for ring,reverse,color in [(rings[0],True,colors[0]),(rings[-1],False,colors[-1])]:
            for i in range(1,len(ring)-1):
                a,b=ring[i:i+2]
                self.triangle(ring[0],b if reverse else a,a if reverse else b,color)

    def box(self,p,size,color,bevel=0):
        x,y,z=(v*.5 for v in size)
        if bevel:
            edge=min(bevel,x*.43,y*.43,z*.43)
            self.loft(p,[(2*x-edge,2*y-edge,bevel,-z),(2*x,2*y,bevel,-z+edge),
                         (2*x,2*y,bevel,z-edge),(2*x-edge,2*y-edge,bevel,z)],[color]*3)
            return
        v=[add(p,(i*x,j*y,k*z)) for k in [-1,1] for j in [-1,1] for i in [-1,1]]
        for a,b,c,d in [(4,5,7,6),(1,0,2,3),(0,4,6,2),(5,1,3,7),(6,7,3,2),(0,1,5,4)]:
            self.quad(v[a],v[b],v[c],v[d],color)

    def tube(self,points,r,color,sides=6):
        rings=[]
        for i,p in enumerate(points):
            axis=normalize(sub(points[min(i+1,len(points)-1)],points[max(0,i-1)]))
            ref=(1,0,0) if abs(axis[0])<.85 else (0,1,0)
            u=normalize(cross(axis,ref)); v=cross(axis,u)
            rings.append([add(p,add(mul(u,r*math.cos(j*TAU/sides)),mul(v,r*math.sin(j*TAU/sides)))) for j in range(sides)])
        for a,b in zip(rings,rings[1:]):
            for i in range(sides):
                k=(i+1)%sides
                self.quad(a[i],a[k],b[k],b[i],color)
        for i in range(1,sides-1):
            self.triangle(rings[0][0],rings[0][i+1],rings[0][i],color)
            self.triangle(rings[-1][0],rings[-1][i],rings[-1][i+1],color)

    def badge(self,p,w,h,slot):
        x,y,z=p
        pts=[(x-w/2,y-h/2,z),(x+w/2,y-h/2,z),(x+w/2,y+h/2,z),(x-w/2,y+h/2,z)]
        uv=[slot_uv(slot,u,v) for u,v in [(0,1),(1,1),(1,0),(0,0)]]
        for ids in [(0,1,2),(0,2,3)]:
            self.triangle(*(pts[i] for i in ids),'ffffff',[uv[i] for i in ids])

    def glass(self,p,w,h,slot):
        x,y,z=p
        shape=rounded(w,h,min(w,h)*.155)
        rings=[[(x+px*s,y+py*s,z+bow) for px,py in shape] for s,bow in [(1,0),(.87,.033),(.5,.071),(.01,.083)]]
        def face(a,b,c):
            uv=[slot_uv(slot,.5+(k[0]-x)/w,.5-(k[1]-y)/h) for k in (a,b,c)]
            self.triangle(a,b,c,'ffffff',uv)
        for a,b in zip(rings,rings[1:]):
            for i in range(len(a)):
                k=(i+1)%len(a)
                face(a[i],a[k],b[k]);face(a[i],b[k],b[i])
        for i in range(1,len(shape)-1):face(rings[-1][0],rings[-1][i],rings[-1][i+1])

    def source(self,name,origin,scale,palette):
        for mat,pos,normals,ids in kenney(name):
            for j in range(0,len(ids),3):
                ix=ids[j:j+3]
                self.triangle(*(add(origin,mul(pos[k],scale)) for k in ix),palette[mat],normals=[normals[k] for k in ix])

    def blocker(self,center,size):
        center=add(self.base,center)
        self.ao_boxes.append((sub(center,mul(size,.5)),add(center,mul(size,.5))))

    def rack_frame(self):
        steel='596872'; edge='889395'; dark='343d49'
        for x in [-3.72,3.72]:
            for z in [-1.24,1.24]:
                self.box((x,.10,z),(.60,.20,.57),'303440',.055)
                self.box((x,1.34,z),(.20,2.46,.22),steel)
                self.box((x,1.36,z-.09),(.33,2.42,.08),'46505d')
                for i in range(5):
                    self.box((x,.68+i*.35,z+.113),(.077,.105,.012),'232b39')
        for y in [.44,2.52]:
            self.box((0,y,0),(7.88,.15,2.89),steel,.045)
            self.box((0,y-.13,1.39),(7.87,.20,.11),dark)
            self.box((0,y+.005,1.455),(7.79,.045,.025),edge)
            self.blocker((0,y,0),(7.84,.14,2.85))
        # Cross braces at the back remain visible through the open bay.
        for sign in [-1,1]:
            self.tube([(sign*3.67,.51,-1.23),(-sign*3.67,2.43,-1.23)],.072,steel)
        self.box((-1.8,1.05,-.03),(3.1,1.05,2.04),'4f5260',.10)
        self.box((-1.8,1.07,1.02),(2.92,.89,.13),'303d49',.03)
        for x in [-3.05,-2.88,-2.71,-2.54,-2.37]:
            self.box((x,1.10,1.093),(.062,.56,.025),'858989')
        self.badge((-1.02,1.21,1.095),.83,.32,6)
        self.box((1.40,.79,0),(2.55,.55,1.97),'454652',.065)
        for i in range(5):
            x=.48+i*.39
            self.tube([(x,.80,.98),(x,.80,1.06)],.11,'a29b85',10)
            self.tube([(x,.80,1.06),(x,.80,1.09)],.060,'272c37',8)
        self.badge((-.18,2.405,1.46),.66,.14,6)
        # Restrained chips along the exposed leading lip.
        for x,w in [(-3.2,.22),(-3.09,.07),(.8,.27),(2.18,.12),(3.13,.18)]:
            self.box((x,2.553,1.457),(w,.018,.009),'aca388')

    def vintage(self,p,w,slot,antenna):
        self.base=p; s=w/.41
        self.source('televisionVintage',(-w/2,0,.11*s),s,{'wood':'9b6b53','metalMedium':'b6a386','metalDark':'514953','metal':'747a74'})
        if antenna:self.source('televisionAntenna',(0,.27*s,.03*s),s*.86,{'metalMedium':'9cabb0'})
        self.glass(((-.205+.151)*s,.134*s,.112*s),.226*s,.176*s,slot)
        for i in range(2):
            x=.15*s; y=(.19-.063*i)*s
            self.tube([(x,y,.108*s),(x,y,.122*s)],.024*s,'454952',12)
            self.box((x,y+.02,.123*s),(.018*s,.037,.016),'c9b38f')
        for i in range(6):
            self.box((.15*s,(.04+.008*i)*s,.112*s),(.057*s,.020,.026),'484753')
        for i in range(4):
            self.box((-.093*s+i*.030*s,.271*s,-.045*s),(.009*s,.012,.067*s),'715545')
        self.blocker((0,.13*s,0),(.395*s,.25*s,.19*s))
        self.base=(0,0,0)

    def monitor(self,p,w,h,slot,portable=False):
        self.base=p
        skin=('8f7684' if slot==5 else '75928b') if portable else ('93999b' if slot==3 else 'b0a79a')
        rim='94a9a0' if portable else 'c1b6a1'
        back='566f71' if portable else '837e7b'
        depth=w*.69; front=depth*.53; cy=.115+h*.5
        self.loft((0,cy,0),[(w*.67,h*.71,h*.11,-depth*.5),(w*.91,h*.90,h*.14,-depth*.21),
                    (w,h,h*.13,front-.22),(w*.98,h*.98,h*.13,front)], [back,skin,rim])
        for x in [-w*.32,w*.32]:
            self.box((x,.08,.15),(w*.20,.16,depth*.58),'373b45',.045)
        sw=w*(.63 if portable else .78); sh=h*(.70 if portable else .67)
        sx=-w*(.112 if portable else .015); sy=cy+h*(.015 if portable else .066)
        self.loft((sx,sy,front),[(sw+.25,sh+.24,.18,-.045),(sw+.21,sh+.2,.17,.054),(sw+.07,sh+.07,.16,.092)],
                  ['54585b','353f48'])
        self.glass((sx,sy,front+.096),sw,sh,slot)
        self.blocker((0,cy,0),(w*.86,h*.85,depth*.90))
        if portable:
            for j in range(2):
                x=w*.344; y=cy+h*(.25-.24*j)
                self.tube([(x,y,front-.015),(x,y,front+.095)],w*.065,'3a484b',12)
                self.tube([(x,y,front+.095),(x,y,front+.11)],w*.045,'91a199',12)
                self.box((x,y+.052,front+.116),(.032,.085,.015),'424d54')
            for i in range(5):
                self.box((w*.34,cy-h*.17-i*.064,front+.006),(w*.17,.030,.018),'39474b')
            for x in [-w*.28,w*.28]:
                self.box((x,h+.23,-.07),(.13,.25,.16),'3a4950',.045)
            self.box((0,h+.37,-.07),(w*.61,.15,.18),'4d5a5e',.055)
            if slot==5:
                self.tube([(-w*.40,h+.07,-.33),(-w*.61,h+.79,-.38)],.032,'a7a49a',8)
        else:
            y=cy-h*.34
            self.box((0,y,front+.008),(w*.83,.25,.048),'494d52',.02)
            for j in range(4):
                x=w*.18+w*.070*j
                self.tube([(x,y,front+.024),(x,y,front+.11)],.080,'a6a49b',10)
            self.badge((-w*.22,y,front+.034),.74,.18,6)
            self.box((w*.06,y+.015,front+.04),(.09,.052,.018),'a9c697')
            # Fold-out face guards and an opaque paper calibration tab.
            for side in [-1,1]:
                x=side*w*.455
                self.tube([(x,cy-h*.17,front-.02),(x,cy-h*.15,front+.17),
                           (x,cy+h*.23,front+.17),(x,cy+h*.25,front-.02)],.043,'777d7a',8)
            self.box((-w*.26,cy+h*.443,front+.009),(.49,.095,.016),'b6a376')
            self.box((-w*.29,cy+h*.443,front+.019),(.14,.018,.009),'665d52')
        # Actual side vents ride the sloping cheek, visible as the camera orbits.
        for side in [-1,1]:
            for i in range(6):
                z=front-.34-i*.115
                half=w*.5*(1-.09*(front-.22-z)/(front-.22+depth*.21))
                self.box((side*half,cy+h*.19,z),(.047,h*.27,.046),'475356')
        for x,z in [(-w*.35,front-.36),(w*.34,front-.39)]:
            self.box((x,h+.109,z),(.19,.016,.055),'ab9e88')
        self.base=(0,0,0)

    def build(self,far):
        self.rack_frame()
        level=2.595
        sign=-1 if far else 1
        self.vintage((-sign*2.01,level,0),3.36,4 if far else 0,not far)
        self.monitor((sign*1.85,level,.02),3.52,2.76,3 if far else 1)
        y=5.68
        for x in [sign*1.85-1.83, sign*1.85+1.83]:
            for z in [-1.18,1.18]:
                self.box((x,(level+y)/2,z),(.106,y-level,.12),'626e73')
        self.box((sign*1.85,y,0),(3.88,.14,2.65),'738084',.035)
        self.blocker((sign*1.85,y,0),(3.87,.14,2.64))
        self.monitor((sign*1.67,y+.07,-.05),2.65 if far else 2.35,1.55 if far else 1.70,5 if far else 2,True)
        # Each powered chassis runs to its own jack on the lower patch bay.
        sources=[(-sign*2.01,3.52,-1.32),(sign*1.67,6.25,-.89),(sign*1.85,3.94,-1.2)]
        for j,start in enumerate(sources):
            x=sign*(3.43+j*.14)
            socket=.48+j*.39
            self.tube([start,(start[0],start[1],start[2]-.23)],.108,'929587',10)
            self.tube([(start[0],start[1],start[2]-.23),(start[0]+sign*.13,start[1]-.34,-1.59),
                       (x,start[1]-.61,-1.64),(x,2.56,-1.65),(x,2.40,-1.30),(x,2.32,.65),
                       (x,2.20,1.46),(x-.08*sign,1.78,1.65),(x-.31*sign,1.04,1.68),
                       ((x+socket)/2,.61+j*.09,1.60),(socket+.25,.62+j*.09,1.44),(socket,.80,1.19),(socket,.80,1.08)],
                      .05,'565564' if j else '8c7361',7)

        # A monitor output feeds its neighbour, independently of the three power leads.
        # The plug collars sit on the outward-facing sides, clear of the glass.
        small=(sign*1.67-sign*(1.325 if far else 1.175),6.28,.17)
        scope=(sign*1.85-sign*1.755,3.48,.38)
        for pos in (small,scope):
            end=add(pos,(-sign*.19,0,0))
            self.tube([pos,end],.104,'b1a490',10)
            self.tube([end,add(end,(-sign*.10,0,0))],.080,'504b5b',8)
        self.tube([add(small,(-sign*.29,0,0)),(small[0]-sign*.46,6.22,.20),
                   (sign*.04,5.94,.53),(-sign*.22,5.76,1.46),(-sign*.29,5.52,1.54),
                   (-sign*.32,4.52,1.52),(-sign*.27,3.64,1.33),(-sign*.18,3.28,.80),
                   add(scope,(-sign*.35,-.06,.14)),add(scope,(-sign*.29,0,0))],.052,'819398',8)
        # Exposed front lip chips, and rub marks on the carry set near its latch.
        for x,length in [(-2.9,.24),(-2.62,.08),(.95,.17),(3.2,.15)]:
            self.box((x,2.488,1.452),(length,.035,.016),'9995a0')
        for x,length in [(-.75,.17),(-.55,.08),(.42,.14)]:
            front=(2.65 if far else 2.35)*.69*.53-.05
            self.box((sign*1.67+x,5.75+.115+(1.55 if far else 1.70)*.955,front+.004),
                     (length,.022,.015),'a5a39e')


# Each low-poly vertex receives short-range ambient occlusion from the major solids.
def ambient(position,normal,boxes):
    point=add(position,mul(normal,.055))
    eligible=[]
    for lo,hi in boxes:
        gap=[max(l-p,0,p-h) for p,l,h in zip(point,lo,hi)]
        if max(gap)>1.45 or max(gap)<.001: continue
        eligible.append((lo,hi))
    if not eligible:return 1.0
    u=normalize(cross(normal,(0,1,0) if abs(normal[1])<.88 else (1,0,0)))
    v=cross(normal,u)
    blocked=0.0
    for i in range(12):
        z=math.sqrt((i+.5)/12)
        r=math.sqrt(1-z*z)
        ray=add(mul(normal,z),add(mul(u,r*math.cos(i*2.39996)),mul(v,r*math.sin(i*2.39996))))
        best=1.45
        for lo,hi in eligible:
            near,far=.001,best
            for p,d,l,h in zip(point,ray,lo,hi):
                if abs(d)<1e-7:
                    if p<l or p>h:far=-1;break
                else:
                    a,b=(l-p)/d,(h-p)/d
                    near=max(near,min(a,b));far=min(far,max(a,b))
                    if far<near: break
            if near<=far:best=near
        blocked+=1-best/1.45
    return 1-.58*blocked/12


def write_glb(racks):
    blob=bytearray()
    doc={'asset':{'version':'2.0','generator':'CRT gallery rack builder','copyright':'Kenney CC0 vintage television and antenna; original rack, monitors and dressing'},
         'buffers':[{}],'bufferViews':[],'accessors':[],'nodes':[],'meshes':[],
         'scenes':[{'nodes':list(range(len(racks)))}],'scene':0}
    def accessor(rows,fmt,kind,component,bounds=False,normalized=False):
        while len(blob)%4:blob.append(0)
        off=len(blob); packed=struct.Struct('<'+fmt)
        for row in rows:blob.extend(packed.pack(*row))
        views=doc['bufferViews'];ix=len(views)
        views.append({'buffer':0,'byteOffset':off,'byteLength':len(blob)-off})
        a={'bufferView':ix,'type':kind,'componentType':component,'count':len(rows)}
        if normalized:a['normalized']=True
        if bounds:
            a['min']=[min(v) for v in zip(*rows)];a['max']=[max(v) for v in zip(*rows)]
        doc['accessors'].append(a)
        return len(doc['accessors'])-1
    for name,rack in racks:
        unique={};vertices=[];normals=[];colors=[];uvs=[];indices=[];cache={}
        for p,n,c,uv in rack.tris:
            p=tuple(round(x,6) for x in p);n=tuple(round(x,5) for x in n)
            key=(p,n,c,uv)
            if key not in unique:
                unique[key]=len(unique)
                if (p,n) not in cache:cache[p,n]=round(255*ambient(p,n,rack.ao_boxes))
                vertices.append(p); normals.append(n); colors.append((*bytes.fromhex(c),cache[p,n]));uvs.append(uv)
            indices.append((unique[key],))
        attrs={'POSITION':accessor(vertices,'fff','VEC3',5126,True),'NORMAL':accessor(normals,'fff','VEC3',5126),
               'COLOR_0':accessor(colors,'BBBB','VEC4',5121,normalized=True),'TEXCOORD_0':accessor(uvs,'ff','VEC2',5126)}
        doc['nodes'].append({'name':name,'mesh':len(doc['meshes'])})
        doc['meshes'].append({'name':name,'primitives':[{'attributes':attrs,'indices':accessor(indices,'H','SCALAR',5123)}]})
        print(name,len(vertices),'vertices,',len(indices)//3,'triangles')
    doc['buffers'][0]['byteLength']=len(blob)
    while len(blob)%4:blob.append(0)
    head=json.dumps(doc,separators=(',',':')).encode()
    head+=b' '*((-len(head))%4)
    (OUT/'service_racks.glb').write_bytes(struct.pack('<4sII',b'glTF',2,28+len(head)+len(blob))+
        struct.pack('<I4s',len(head),b'JSON')+head+struct.pack('<I4s',len(blob),b'BIN\0')+blob)


if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    make_atlas()
    racks=[]
    for name,far in [('NearRack',False),('FarRack',True)]:
        rack=Rack();rack.build(far);racks.append((name,rack))
    write_glb(racks)
