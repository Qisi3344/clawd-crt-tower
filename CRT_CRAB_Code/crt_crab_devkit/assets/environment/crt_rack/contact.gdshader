shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, shadows_disabled;
uniform float coverage = 1.0;
uniform vec2 footprint = vec2(7.44,2.48);
uniform vec2 sheet_size = vec2(10.8,5.6);
uniform float feet = 1.0;
uniform sampler2D masks : filter_linear_mipmap, repeat_disable;
uniform vec2 tile = vec2(-1.0);
void fragment() {
	vec2 p = (UV-0.5)*sheet_size;
	vec2 half_body = footprint*0.5;
	float penumbra = clamp(min(footprint.x,footprint.y)*0.30,0.12,0.90);
	vec2 outside = max(abs(p)-half_body*0.92,vec2(0.0));
	float under = exp(-dot(outside,outside)/(penumbra*penumbra));
	vec2 shoe = (abs(p)-half_body)/max(half_body*vec2(0.17,0.30),vec2(0.10));
	float contact = exp(-dot(shoe,shoe));
	ALBEDO = vec3(0.022,0.017,0.040);
	float amount = min(0.82,(0.59-0.14*feet)*under+feet*0.42*contact);
	if (tile.x>=0.0) amount = texture(masks,(tile+UV)/vec2(4.0,3.0)).r;
	ALPHA = coverage*amount;
}
