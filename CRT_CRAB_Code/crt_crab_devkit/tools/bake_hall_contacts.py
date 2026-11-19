"""Bake the lower triangles of the imported hall props into feathered contact masks."""
import json
import struct
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/environment/crt_rack"
TILE = 128
ASSETS = (
    "furniture-kit__desk", "furniture-kit__chairDesk", "furniture-kit__bookcaseOpen",
    "furniture-kit__cardboardBoxOpen", "furniture-kit__computerScreen",
    "furniture-kit__computerKeyboard", "furniture-kit__lampRoundTable", "mini-arcade__arcade-machine",
    "mini-arcade__ticket-machine", "mini-arcade__vending-machine", "factory-kit__machine-fortified",
    "factory-kit__machine",
)


def triangles(path):
    raw = path.read_bytes()
    size = struct.unpack_from("<I", raw, 12)[0]
    doc = json.loads(raw[20:20+size])
    data = raw[28+size:]

    def read(index):
        accessor = doc["accessors"][index]
        view = doc["bufferViews"][accessor["bufferView"]]
        component = {5126: "f", 5125: "I", 5123: "H", 5121: "B"}[accessor["componentType"]]
        fmt = struct.Struct("<"+component*{"VEC3": 3, "SCALAR": 1}[accessor["type"]])
        offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
        stride = view.get("byteStride", fmt.size)
        return [fmt.unpack_from(data, offset+i*stride) for i in range(accessor["count"])]

    def walk(index, scale, offset):
        node = doc["nodes"][index]
        # These normalized source GLBs only use axis-aligned transforms.
        if "matrix" in node or "rotation" in node:
            raise ValueError(f"Unexpected transform in {path}, node {index}")
        offset = [p+k*t for p,k,t in zip(offset,scale,node.get("translation", [0,0,0]))]
        scale = [a*b for a,b in zip(scale,node.get("scale", [1,1,1]))]
        if "mesh" in node:
            for part in doc["meshes"][node["mesh"]]["primitives"]:
                points = [tuple(t+k*v for t,k,v in zip(offset,scale,p)) for p in read(part["attributes"]["POSITION"])]
                ids = [value[0] for value in read(part["indices"])]
                for i in range(0,len(ids),3):
                    yield [points[j] for j in ids[i:i+3]]
        for child in node.get("children", []):
            yield from walk(child,scale,offset)
    return [tri for node in doc["scenes"][doc.get("scene",0)]["nodes"]
            for tri in walk(node,[1,1,1],[0,0,0])]


def below(tri, height):
    result = []
    for a,b in zip(tri,tri[1:]+tri[:1]):
        if a[1]<=height:
            result.append(a)
        if (a[1]<=height)!=(b[1]<=height):
            t = (height-a[1])/(b[1]-a[1])
            result.append(tuple(x+t*(y-x) for x,y in zip(a,b)))
    return result


def mask_for(path):
    faces = triangles(path)
    points = [p for tri in faces for p in tri]
    lo,hi = [list(map(fn,zip(*points))) for fn in (min,max)]
    sx,sy,sz = [b-a for a,b in zip(lo,hi)]
    contact = Image.new("L",(TILE,TILE))
    belly = Image.new("L",(TILE,TILE))
    for im,height in [(contact,min(0.12,sy*0.09)),(belly,min(0.8,sy*0.35))]:
        d = ImageDraw.Draw(im)
        for tri in faces:
            poly = below(tri,lo[1]+height)
            if len(poly)>=3:
                xy = [((0.15+(x-lo[0])/sx*0.70)*TILE,(0.15+(z-lo[2])/sz*0.70)*TILE) for x,_,z in poly]
                d.polygon(xy,fill=255)
    tight = contact.filter(ImageFilter.GaussianBlur(2.3)).point(lambda c: int(c*0.42))
    broad = belly.filter(ImageFilter.GaussianBlur(6.5)).point(lambda c: int(c*0.32))
    return ImageChops.add(tight,broad)


if __name__=="__main__":
    atlas = Image.new("L",(4*TILE,3*TILE))
    slots = {}
    for i,asset in enumerate(ASSETS):
        atlas.paste(mask_for(ROOT/"assets/environment/optimized"/(asset+".glb")),((i%4)*TILE,(i//4)*TILE))
        slots[asset] = [i%4,i//4]
    atlas.save(OUTPUT/"contact_masks.png")
    (OUTPUT/"contact_slots.json").write_text(json.dumps(slots,indent=2)+"\n",encoding="utf-8")
