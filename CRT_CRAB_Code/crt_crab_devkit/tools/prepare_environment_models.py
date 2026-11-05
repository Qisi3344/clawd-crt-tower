"""Run with Blender --background --python. Normalizes actual CC0 source GLBs."""
import bpy, json, hashlib
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
records=json.loads((ROOT/'assets/environment/source_manifest.json').read_text())
heights={'arcade-machine':6.1,'vending-machine':6.5,'ticket-machine':3.1,'desk':3.1,'bookcaseOpen':5.8,'chairDesk':3.5,'computerKeyboard':0.16,'computerScreen':1.5,'cardboardBoxOpen':1.2,'lampRoundTable':1.6,'machine':5.5,'machine-fortified':6.3,'pipe-large-long':3,'pipe-large-bend':1.8,'pipe-large-valve':2,'structure-high':8,'catwalk-straight':0.6,'workbench':4.5,'tool-hammer':0.6,'metal-panel-screws':3}

def tint(rgb):
    r,g,b=rgb
    v=max(rgb)
    if v<0.06:return (r,g,b)
    if max(rgb)-min(rgb)<0.12:return (v*0.63,v*0.68,v*0.69)
    if r>g*1.2 and g>b*1.1:return (v*0.55,v*0.64,v*0.58)
    if g>r*1.2 and g>b*1.1:return (v*0.28,v*0.57,v*0.55)
    if b>r*1.2:return (v*0.34,v*0.43,v*0.55)
    if r>g*1.3:return (v*0.59,v*0.31,v*0.43)
    return (r*0.65,g*0.68,b*0.70)

for entry in records:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    source=ROOT/entry['original']
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    points=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
    lo=Vector(tuple(min(p[i] for p in points) for i in range(3)))
    hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
    name=source.stem
    factor=heights[name]/max(hi.z-lo.z,0.001)
    parent=bpy.data.objects.new('NormalizedRoot',None)
    bpy.context.collection.objects.link(parent)
    for o in list(bpy.context.scene.objects):
        if o!=parent and o.parent is None:o.parent=parent
    parent.scale=(factor,)*3
    parent.location=Vector((-(hi.x+lo.x)/2,-(hi.y+lo.y)/2,-lo.z))*factor
    for image in list(bpy.data.images):
        # Force Blender's lazy external image load before iterating pixel values.
        if not len(image.pixels):continue
        pixels=list(image.pixels)
        for i in range(0,len(pixels),4):pixels[i:i+3]=tint(pixels[i:i+3])
        if image.packed_file:image.unpack(method='REMOVE')
        image.pixels=pixels
        image.filepath_raw=str(ROOT/'.tools/environment'/(entry['id']+'-palette.png'))
        image.file_format='PNG'
        image.save()
        image.pack()
    for material in bpy.data.materials:
        if not material.use_nodes:continue
        for node in material.node_tree.nodes:
            if node.type=='BSDF_PRINCIPLED':
                node.inputs['Roughness'].default_value=0.92
                node.inputs['Metallic'].default_value=0.04
                base=node.inputs['Base Color']
                if not base.is_linked:base.default_value=(*tint(base.default_value[:3]),1)
    destination=ROOT/'assets/environment/optimized'/(entry['id']+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(destination),export_format='GLB',export_animations=False,export_cameras=False,export_lights=False)
    entry['optimized']=str(destination.relative_to(ROOT)).replace('\\','/')
    entry['modification']='uniform scale, ground pivot, palette tint, matte materials; original geometry retained'
    entry['size']=[round((hi.x-lo.x)*factor,3),heights[name],round((hi.y-lo.y)*factor,3)]
    entry['optimized_sha256']=hashlib.sha256(destination.read_bytes()).hexdigest()
    print('PREPARED',entry['id'],entry['size'])
(ROOT/'assets/environment/source_manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
