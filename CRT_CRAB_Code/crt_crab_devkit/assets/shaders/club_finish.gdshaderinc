// Shared enamel, cloth-safe grading and phosphor falloff for the 3-D hall.
uniform sampler2D patina_map : repeat_enable, filter_linear_mipmap;
uniform float spill_energy = 1.0;

vec3 club_grade(vec3 c, float amount) {
	float lum = dot(c,vec3(0.26,0.55,0.19));
	float warm = smoothstep(0.015,0.36,c.r-c.b);
	vec3 cool = mix(c,lum*vec3(0.94,0.89,1.06),0.15+0.38*warm);
	return mix(c,cool*(0.96-0.09*warm),amount);
}

vec3 club_worn(vec3 c, vec3 p, vec3 n, float amount) {
	vec3 a = abs(normalize(n));
	vec2 uv = a.y>max(a.x,a.z) ? p.xz : (a.x>a.z ? p.zy : p.xy);
	vec3 marks = texture(patina_map,uv*0.29).rgb;
	float bevel = smoothstep(0.018,0.20,1.0-max(a.x,max(a.y,a.z)));
	float soil = marks.b*(0.09+0.12*bevel);
	vec3 used = c*(1.0-soil+0.045*(marks.r-0.5));
	return mix(c,mix(used,vec3(0.54,0.51,0.62),marks.g*(0.16+0.44*bevel)),amount);
}

vec3 club_reflection(vec3 n, vec3 view_dir, vec3 c) {
	float grazing = pow(clamp(1.0-abs(dot(normalize(n),normalize(view_dir))),0.0,1.0),2.8);
	return vec3(0.052,0.041,0.084)*grazing*(0.5+dot(c,vec3(0.33)));
}

// The closest point on a luminous rectangle drives both a narrow bezel glow
// and a wider, weaker reflection that reaches the shelf or control deck.
float club_screen_spill(vec3 p, vec2 half_size) {
	vec2 edge = max(abs(p.xy)-half_size,vec2(0.0));
	float radius = length(vec3(edge,p.z));
	float reach = max(half_size.y,0.32);
	float front = smoothstep(-0.62*reach,-0.09*reach,p.z);
	float normalized = radius/reach;
	return front*(0.19*exp(-4.2*normalized)+0.075*exp(-1.25*normalized))*spill_energy;
}
