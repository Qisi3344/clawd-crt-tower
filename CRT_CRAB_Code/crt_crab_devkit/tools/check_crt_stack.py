"""Check exported, real Godot CRT bounds. Stdlib only; run after crt_geometry_qa.gd."""
import json, math, sys
from pathlib import Path


def cross(a,b,c):
    return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])


def area(poly):
    return abs(sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(poly,poly[1:]+poly[:1])))/2 if poly else 0


def clip(subject, boundary):
    # Normalize the clip polygon winding; Godot hulls need not share one winding.
    if sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(boundary,boundary[1:]+boundary[:1]))<0:
        boundary=list(reversed(boundary))
    for a,b in zip(boundary,boundary[1:]+boundary[:1]):
        source,subject=subject,[]
        if not source: break
        prev=source[-1]; dp=cross(a,b,prev)
        for cur in source:
            dc=cross(a,b,cur)
            if (dc>=0)!=(dp>=0):
                t=dp/(dp-dc)
                subject.append([prev[0]+t*(cur[0]-prev[0]),prev[1]+t*(cur[1]-prev[1])])
            if dc>=0: subject.append(cur)
            prev,dp=cur,dc
    return subject


def margin(point,poly):
    if not poly: return -1
    if sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(poly,poly[1:]+poly[:1]))<0: poly=list(reversed(poly))
    return min(cross(a,b,point)/math.dist(a,b) for a,b in zip(poly,poly[1:]+poly[:1]) if math.dist(a,b)>1e-8)


def rotate(p,yaw):
    a=math.radians(yaw); c,s=math.cos(a),math.sin(a)
    return [c*p[0]+s*p[1],-s*p[0]+c*p[1]]


def polygon(device,key):
    return [[q[0]+device['position'][0],q[1]+device['position'][2]] for p in device[key] for q in [rotate(p,device['rotation'][1])]]


def overlaps(a,b):
    # Separating-axis check for the actual rotated component boxes, not world AABBs.
    if min(a['high'],b['high'])-max(a['low'],b['low'])<0.0001: return False
    for poly in [a['poly'],b['poly']]:
        for p,q in zip(poly,poly[1:]+poly[:1]):
            axis=[p[1]-q[1],q[0]-p[0]]
            pa=[sum(x*y for x,y in zip(v,axis)) for v in a['poly']]
            pb=[sum(x*y for x,y in zip(v,axis)) for v in b['poly']]
            if min(max(pa),max(pb))-max(min(pa),min(pb))<0.0001: return False
    return True


def run(data,layout):
    assert data["passed"], "native mesh checks failed"
    assert len(layout)==len(data["devices"])==12
    assert len({d["computer_id"] for d in layout})==12
    devices=[]
    for spec,mesh in zip(layout,data['devices']):
        assert spec['computer_id']==mesh['computer_id']
        dev={**mesh,**spec}; devices.append(dev)
        assert abs(dev['rotation'][0])+abs(dev['rotation'][2])<1e-7, 'horizontal bearing faces required'
        dev['contact']=polygon(dev,'bottom_polygon')
        dev['roof']=polygon(dev,'top_polygon')
        dev['bottom_y']=dev['position'][1]+mesh['bottom_y']
        dev['top_y']=dev['position'][1]+mesh['top_y']
        offset=rotate(mesh['mass_center'],dev['rotation'][1])
        dev['com']=[dev['position'][0]+offset[0],dev['position'][2]+offset[1]]
        dev['load_mass']=dev['mass']; dev['load_com']=dev['com'][:]
        dev['parts_world']=[]
        for part in mesh['parts']:
            dev['parts_world'].append({'poly':polygon({**dev,'part_poly':part['poly']},'part_poly'),'low':part['low']+dev['position'][1],'high':part['high']+dev['position'][1],'name':part['name']})
    by_id={d['computer_id']:d for d in devices}
    for d in devices:
        if d['index']<4:
            assert d['supported_by']=='original_platform'
        else:
            assert d['supported_by'] in by_id, 'missing supporting CRT'
            assert by_id[d['supported_by']]['index']//4==d['index']//4-1, 'support must be on the preceding tier'

    # Propagate the mass of the whole column, not just each empty upper case.
    for d in reversed(devices):
        lower=by_id.get(d.get('supported_by'))
        if lower:
            total=lower['load_mass']+d['load_mass']
            lower['load_com']=[(a*lower['load_mass']+b*d['load_mass'])/total for a,b in zip(lower['load_com'],d['load_com'])]
            lower['load_mass']=total
    reports=[]; errors=[]
    for d in devices:
        lower=by_id.get(d.get('supported_by'))
        support=lower['roof'] if lower else [[-12.1,-12.1],[12.1,-12.1],[12.1,12.1],[-12.1,12.1]]
        contact=clip(d['contact'],support)
        gap=d['bottom_y']-(lower['top_y'] if lower else -1.1)
        coverage=area(contact)/area(d['contact'])
        own_margin=margin(d['com'],contact); load_margin=margin(d['load_com'],contact)
        ok=abs(gap)<0.0001 and coverage>=0.30 and own_margin>=0.08 and load_margin>=0.08
        reports.append({'index':d['index'],'id':d['computer_id'],'support':lower['computer_id'] if lower else 'original platform','gap':round(gap,6),'contact_area':round(area(contact),4),'footprint_coverage':round(coverage,4),'own_com_margin':round(own_margin,4),'loaded_com_margin':round(load_margin,4),'passed':ok})
        if not ok: errors.append('support '+d['computer_id'])
    below_floor=[[d['index'],p['name']] for d in devices for p in d['parts_world'] if p['low'] < -1.1001]
    if below_floor: errors.append('parts below original platform')
    collisions=[]
    for i,a in enumerate(devices):
        for b in devices[i+1:]:
            for pa in a['parts_world']:
                for pb in b['parts_world']:
                    if overlaps(pa,pb): collisions.append([a['index'],pa['name'],b['index'],pb['name']])
    if collisions: errors.append('interpenetrating CRT parts')
    decor_collisions=[]
    unintended_supports=[]
    for d in devices:
        for pa in d['parts_world']:
            for pb in data['exterior_parts']:
                if overlaps(pa,pb): decor_collisions.append([d['index'],pa['name'],pb['name']])
                if abs(pa['low']-pb['high'])<0.0001 and area(clip(pa['poly'],pb['poly']))>0.0001:
                    unintended_supports.append([d['index'],pa['name'],pb['name']])
    if decor_collisions: errors.append('CRT intersects existing large exterior props')
    if unintended_supports: errors.append('CRT rests on an exterior prop')
    return {'passed':not errors,'devices':reports,'collisions':collisions,'below_floor':below_floor,'decor_collisions':decor_collisions,'unintended_supports':unintended_supports,'mesh_checks_passed':data['passed'],'errors':errors,'method':'Actual mesh flat-face hulls + yaw-transformed component OBB SAT; uniform case/base mass proxy with cumulative upper loads; 0.0001 contact tolerance.'}


if __name__=='__main__':
    root=Path(__file__).resolve().parents[1]
    data=json.loads((root/'artifacts/crt-geometry.json').read_text(encoding='utf-8'))
    layout=json.loads((root/'data/monitor_layout.json').read_text(encoding='utf-8'))
    report=run(data,layout)
    (root/'artifacts/crt-stack-check.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(report,ensure_ascii=False,indent=2))
    sys.exit(0 if report['passed'] else 1)
