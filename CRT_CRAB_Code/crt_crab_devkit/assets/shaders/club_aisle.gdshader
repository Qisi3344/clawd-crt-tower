shader_type spatial;
render_mode unshaded, shadows_disabled;
#include "res://assets/shaders/club_haze.gdshaderinc"
varying vec3 position_world;
void vertex() { position_world = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p = position_world.xz;
	float radius = length(p);
	vec2 seam = abs(fract((p+0.01)/4.0)-0.5);
	float grout = smoothstep(0.48,0.499,max(seam.x,seam.y))*(1.0-smoothstep(24.0,54.0,radius));
	vec3 floor_color = mix(vec3(0.105,0.092,0.145),vec3(0.087,0.084,0.124),grout);
	float wash = exp(-0.07*abs(p.x)-0.21*abs(p.y-24.0));
	floor_color += wash*vec3(0.07,0.035,0.047);
	ALBEDO = mix(floor_color,club_haze(normalize(position_world-CAMERA_POSITION_WORLD)),smoothstep(39.0,78.0,radius));
}
