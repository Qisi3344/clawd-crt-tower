shader_type spatial;
uniform vec4 outer_color : source_color = vec4(0.16,0.14,0.20,1.0);
uniform vec4 core_color : source_color = vec4(0.21,0.18,0.25,1.0);
uniform vec4 route_color : source_color = vec4(0.31,0.46,0.43,1.0);
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float segment(vec2 p,vec2 a,vec2 b) {
    vec2 v=b-a;
    return length(p-a-v*clamp(dot(p-a,v)/dot(v,v),0.0,1.0));
}
void fragment() {
    vec2 p=world_pos.xz;
    vec2 tile=floor(p/1.6);
    float cell=hash(tile);
    float core=1.0-step(10.6,max(abs(p.x),abs(p.y)));
    vec3 color=mix(outer_color.rgb,core_color.rgb,core);
    color *= mix(0.96,1.04,step(0.48,cell));
    vec2 edge=min(fract(p/1.6),1.0-fract(p/1.6));
    float grout=1.0-step(0.007,min(edge.x,edge.y));
    color=mix(color,color*0.70,grout*0.6);
    // One painted system crosses the original floor meshes, without raised geometry.
    vec2 q=vec2(abs(p.x),p.y);
    float route=min(segment(q,vec2(0,9.2),vec2(6,9.2)),segment(q,vec2(6,9.2),vec2(10,6)));
    route=min(route,segment(q,vec2(10,6),vec2(14,3.8)));
    route=min(route,segment(q,vec2(14,3.8),vec2(20,3.8)));
    float lane=(1.0-step(0.065,route))*mix(0.48,0.82,step(0.18,hash(floor(p*5.0))));
    color=mix(color,route_color.rgb,lane);
    float dash=(1.0-step(0.024,abs(route-0.28)))*step(0.50,fract((q.x+q.y)*1.25));
    color=mix(color,route_color.rgb*0.75,dash*0.6);
    float traffic=1.0-step(0.7,route);
    vec2 local=fract(p/1.6)-vec2(0.5);
    float scratch=(1.0-step(0.012,abs(local.y-local.x*0.24)))*(1.0-step(0.31,abs(local.x)))*step(0.65,cell);
    // Drag marks around the existing tower footprint; no photo textures or grime noise.
    float drag=min(segment(p,vec2(-1.8,7.4),vec2(-2.2,8.8)),segment(p,vec2(2.2,7.3),vec2(2.6,8.7)));
    drag=min(drag,segment(p,vec2(-6.5,1.8),vec2(-8.1,2.2)));
    color=mix(color,color*1.33,scratch*(0.13+traffic*0.28)+(1.0-step(0.025,drag))*0.32);
    float corner=step(21.5,abs(p.x))*step(20.5,-p.y);
    color*=1.0-corner*(0.08+step(0.5,cell)*0.10);
    ALBEDO=color;
    METALLIC=0.0;
    ROUGHNESS=mix(0.80,0.68,traffic);
    SPECULAR=0.23;
}
