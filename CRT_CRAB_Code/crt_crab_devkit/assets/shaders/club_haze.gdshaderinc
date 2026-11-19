// A quiet band of haze below eye level joins the far aisle to the floor.
vec3 club_haze(vec3 d) {
	float bank = 0.51 + 0.22 * sin(4.0*d.x + 2.8*d.z) + 0.15 * cos(6.3*d.z - 3.7*d.x);
	float haze = exp(-7.8 * abs(d.y + 0.11 + 0.055 * bank)) * (0.58 + 0.36*bank);
	vec3 night = mix(vec3(0.045,0.060,0.100), vec3(0.037,0.032,0.071), smoothstep(-0.22,0.25,d.y));
	return night + mix(vec3(0.057,0.095,0.12),vec3(0.102,0.068,0.12),bank) * haze;
}
