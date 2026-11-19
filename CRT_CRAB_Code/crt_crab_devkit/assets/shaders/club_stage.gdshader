shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform float coverage : hint_range(0.0,1.0) = 1.0;
uniform float mist : hint_range(0.0,1.0) = 0.0;
uniform bool woven_carpet = false;
#include "res://assets/shaders/club_finish.gdshaderinc"
uniform bool entry_display = false;
uniform sampler2D signals : source_color, filter_linear_mipmap;
uniform vec2 signal_tile;
varying vec3 world_normal;
varying vec3 mesh_normal;
varying vec3 local_position;
void vertex() {
	local_position = VERTEX;
	mesh_normal = NORMAL;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	// Ordered coverage keeps this opaque scenery in the depth buffer during a cutaway.
	float threshold = fract(52.9829189 * fract(dot(floor(FRAGCOORD.xy), vec2(0.06711056,0.00583715))));
	if (coverage <= threshold) { discard; }
	float diffuse = dot(normalize(world_normal),normalize(vec3(-0.45,0.8,-0.35)));
	float shade = 0.58 + 0.23*smoothstep(-0.28,-0.05,diffuse) + 0.19*smoothstep(0.58,0.78,diffuse);
	vec3 paint = COLOR.rgb;
	// Staggered woven waves and small two-colour lozenges, inside the stitched binding.
	if (woven_carpet && local_position.y < -1.115 && world_normal.y > 0.8) {
		vec2 p = local_position.xz;
		float row = floor(p.y/0.92);
		vec2 cell = vec2(fract(p.x/1.32+0.5*mod(row,2.0))-0.5,fract(p.y/0.92)-0.5);
		float wave = abs(cell.y+0.28-0.29*abs(cell.x*2.0));
		float thread = 1.0-smoothstep(0.012,0.052,wave);
		paint = mix(paint,vec3(0.34,0.27,0.35),0.62*thread);
		float lozenge = abs(cell.x)*1.7+abs(cell.y-0.22);
		vec3 yarn = mix(vec3(0.45,0.32,0.38),vec3(0.32,0.44,0.44),mod(row,2.0));
		paint = mix(paint,yarn,(1.0-smoothstep(0.075,0.12,lozenge))*0.75);
	}
	vec3 finish = club_worn(club_grade(paint,0.8),local_position,mesh_normal,woven_carpet?0.0:0.75)*shade;
	finish += club_reflection(NORMAL,VIEW,paint)*(woven_carpet?0.0:0.70);
	if (entry_display) {
		vec3 p = local_position-vec3(0.0,3.26,0.85);
		p.z += 0.14*p.y;
		float screen = float(distance(COLOR.rgb,vec3(69.0,93.0,101.0)/255.0)<0.025);
		if (screen>0.5 && abs(p.x)<0.86 && abs(p.y)<0.62 && p.z>-0.10) {
			vec2 uv = clamp(vec2(p.x/1.72+0.5,0.5-p.y/1.24),0.02,0.98);
			finish = texture(signals,(signal_tile+uv)/vec2(4.0,2.0)).rgb*0.78;
		} else {
			vec3 tint = signal_tile.x<1.5 ? vec3(0.75,0.50,0.27) : vec3(0.32,0.68,0.67);
			finish += tint*club_screen_spill(p,vec2(0.86,0.62))*(0.58+0.45*paint);
		}
	}
	ALBEDO = mix(finish,vec3(0.068,0.074,0.12),mist);
}
