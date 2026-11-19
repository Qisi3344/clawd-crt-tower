shader_type spatial;
render_mode unshaded, blend_add, cull_front, shadows_disabled, depth_test_disabled, depth_draw_never;
uniform vec4 tint : source_color;
uniform vec2 mouth;
uniform vec2 footprint;
uniform float drop;
uniform float strength = 0.032;
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
varying vec3 local_position;
varying vec3 local_eye;
void vertex() {
	// Unit cylinder; both elliptical caps match the tube and the footprint in world space.
	float t = clamp(0.5 - VERTEX.y,0.0,1.0);
	VERTEX.xz *= mix(mouth,footprint,t);
	VERTEX.y = -drop*t;
	local_position = VERTEX;
	local_eye = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX[3]).xyz;
}
void fragment() {
	vec3 ray = normalize(local_position-local_eye);
	float exit_dist = length(local_position-local_eye);
	// Clip the interval against a bounding box before sampling the fog inside the cone.
	vec3 safe_ray = mix(vec3(0.00001),ray,greaterThan(abs(ray),vec3(0.00001)));
	vec3 a = (vec3(-footprint.x,-drop,-footprint.y)-local_eye)/safe_ray;
	vec3 b = (vec3(footprint.x,0.0,footprint.y)-local_eye)/safe_ray;
	vec3 near_box = min(a,b);
	float start = max(0.0,max(near_box.x,max(near_box.y,near_box.z)));
	float depth = textureLod(scene_depth,SCREEN_UV,0.0).r;
	vec3 ndc = vec3(SCREEN_UV*2.0-1.0, mix(CLIP_SPACE_FAR,1.0,depth));
	vec4 hit = INV_PROJECTION_MATRIX * vec4(ndc,1.0);
	float end = min(exit_dist,length(hit.xyz/hit.w));
	float step_size = max(0.0,end-start)/10.0;
	float fog = 0.0;
	for (int i=0; i<10; i++) {
		vec3 p = local_eye + ray * (start+(float(i)+0.5)*step_size);
		float t = clamp(-p.y/drop,0.0,1.0);
		vec2 q = p.xz / mix(mouth,footprint,t);
		float density = pow(max(0.0,1.0-dot(q,q)),1.6);
		fog += density * mix(1.0,0.24,t) * step_size;
	}
	ALBEDO = tint.rgb;
	ALPHA = 1.0-exp(-strength*fog);
}
