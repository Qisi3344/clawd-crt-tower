shader_type spatial;
render_mode shadows_disabled, ambient_light_disabled, specular_disabled;
uniform float coverage : hint_range(0.0,1.0) = 1.0;
uniform float mist : hint_range(0.0,1.0) = 0.18;
uniform sampler2D artwork : source_color, repeat_disable, filter_linear_mipmap;
#include "res://assets/shaders/club_finish.gdshaderinc"
uniform float layout_sign = 1.0;
uniform int program_shift = 0;
vec3 program_tint(int original) {
	int slot = (original+program_shift)%6;
	if (slot==0) return vec3(0.64,0.59,0.71);
	if (slot==1) return vec3(0.83,0.55,0.30);
	if (slot==2) return vec3(0.26,0.66,0.73);
	if (slot==3) return vec3(0.34,0.65,0.47);
	if (slot==4) return vec3(0.61,0.39,0.66);
	return vec3(0.36,0.58,0.76);
}
float resting_shadow(vec3 p,vec2 half_size) {
	vec2 outside = max(abs(p.xz)-half_size,vec2(0.0));
	return exp(-5.2*length(outside)-10.0*abs(p.y));
}
varying vec3 mesh_normal;
varying vec3 world_normal;
varying vec3 rack_position;
void vertex() {
	rack_position = VERTEX;
	mesh_normal = NORMAL;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	float dither = fract(52.9829189*fract(dot(floor(FRAGCOORD.xy),vec2(0.06711056,0.00583715))));
	if (coverage <= dither) { discard; }
	vec3 ink = texture(artwork,UV).rgb;
	vec3 n = normalize(world_normal);
	float facing = dot(n,normalize(vec3(-0.35,0.8,-0.55)));
	float cel = 0.42+0.24*smoothstep(-0.22,-0.05,facing)+0.28*smoothstep(0.48,0.67,facing);
	vec3 shell = club_worn(club_grade(COLOR.rgb,1.0),rack_position,mesh_normal,1.0);
	float warmth = smoothstep(0.01,0.32,COLOR.r-COLOR.b);
	shell *= mix(vec3(0.84,0.82,0.94),vec3(0.77,0.76,0.91),warmth);
	float occlusion = pow(COLOR.a,1.45);
	vec3 paint = shell*ink*cel*occlusion+club_reflection(NORMAL,VIEW,shell)*0.82;
	// A restrained veneer grain on the brown shell, filtered away in the distant view.
	float wood = smoothstep(0.055,0.11,COLOR.r-COLOR.g)*smoothstep(0.03,0.08,COLOR.g-COLOR.b);
	float grain_pos = rack_position.z*33.0+rack_position.y*24.0+1.9*sin(rack_position.x*2.5);
	float grain = sin(grain_pos)*clamp(1.0-fwidth(grain_pos)*0.30,0.0,1.0);
	paint *= 1.0+wood*0.060*grain;
	bool phosphor = UV.y<0.5 || UV.x<0.5;
	if (phosphor) {
		vec2 cells = UV*vec2(4.0,2.0);
		int slot = (int(floor(cells.x))+4*int(floor(cells.y))+program_shift)%6;
		ink = texture(artwork,(vec2(float(slot%4),float(slot/4))+fract(cells))/vec2(4.0,2.0)).rgb;
		float fresnel = pow(1.0-max(dot(NORMAL,VIEW),0.0),2.5);
		paint = ink*0.85 + vec3(0.055,0.09,0.10)*fresnel;
	} else {
		// Centers follow the three glass meshes authored by the rack builder.
		float sign_x = layout_sign;
		bool far_set = sign_x<0.0;
		float rest = max(resting_shadow(rack_position-vec3(-sign_x*2.01,2.595,0.0),vec2(1.61,0.77)),
			resting_shadow(rack_position-vec3(sign_x*1.85,2.595,0.02),vec2(1.38,0.78)));
		rest = max(rest,resting_shadow(rack_position-vec3(sign_x*1.67,5.75,-0.05),vec2(1.0,0.54)));
		rest = max(rest,resting_shadow(rack_position-vec3(-1.8,0.515,-0.03),vec2(1.49,0.94)));
		paint *= 1.0-0.43*rest*smoothstep(0.25,0.90,mesh_normal.y);
		vec3 wood_pos = vec3(-sign_x*2.01-0.44,3.69,0.94);
		vec3 scope_pos = vec3(sign_x*1.85-0.053,4.27,1.49);
		vec3 small_pos = vec3(sign_x*1.67-(far_set?0.297:0.263),far_set?6.66:6.74,far_set?1.08:0.96);
		vec3 bounce = club_screen_spill(rack_position-wood_pos,vec2(0.93,0.72))*program_tint(far_set?4:0);
		bounce += club_screen_spill(rack_position-scope_pos,vec2(1.37,0.92))*program_tint(far_set?3:1);
		bounce += club_screen_spill(rack_position-small_pos,vec2(far_set?0.84:0.74,0.57))*program_tint(far_set?5:2);
		paint += bounce*(0.62+0.48*shell)*mix(0.76,1.0,occlusion);
	}
	ALBEDO = vec3(0.0);
	EMISSION = mix(paint,vec3(0.068,0.074,0.12),mist);
}
