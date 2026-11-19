shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D screen_texture : source_color, filter_nearest;
uniform float interference = 0.0;
uniform float idle_shimmer = 0.0;
uniform float shimmer_phase = 0.0;
uniform vec2 content_scale = vec2(1.0);
uniform vec4 screen_region = vec4(0.0,0.0,1.0,1.0);
void fragment() {
	vec2 uv = UV;
	vec2 d = uv - 0.5;
	uv += d * dot(d,d) * 0.035;
	uv.x += sin(uv.y * 100.0 + TIME * 24.0) * interference * 0.012;
	uv = (uv-0.5)/content_scale+0.5;
	float inside = step(0.0,uv.x)*step(uv.x,1.0)*step(0.0,uv.y)*step(uv.y,1.0);
	vec3 col = texture(screen_texture,screen_region.xy+clamp(uv,0.002,0.998)*screen_region.zw).rgb*inside;
	float scan = 0.99 + 0.008 * sin(UV.y * 180.0 * 6.28318);
	float edge = 1.0 - 0.15 * pow(length(d) * 1.3,3.0);
	ALBEDO = col * scan * edge + interference * 0.12;
	float cycle = TIME * 0.14 + shimmer_phase;
	float sweep = exp(-100.0 * abs(fract(cycle) * 2.0 - 0.5 - UV.y));
	ALBEDO *= 1.0 + idle_shimmer * (0.009 * sin(cycle * 4.3) + 0.024 * sweep);
}
