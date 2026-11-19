shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, shadows_disabled;
uniform sampler2D scene : hint_screen_texture, repeat_disable, filter_linear;
uniform float coverage = 1.0;
void fragment() {
	float threshold = fract(52.9829189 * fract(dot(floor(FRAGCOORD.xy),vec2(0.06711056,0.00583715))));
	if (coverage <= threshold) { discard; }
	float near_lens = 1.0-smoothstep(19.0,35.0,length(VERTEX));
	vec2 texel = (1.6*VIEWPORT_SIZE.y/800.0)/VIEWPORT_SIZE;
	vec3 blur = texture(scene,SCREEN_UV).rgb*0.20;
	blur += texture(scene,SCREEN_UV+texel).rgb*0.20;
	blur += texture(scene,SCREEN_UV-texel).rgb*0.20;
	blur += texture(scene,SCREEN_UV+vec2(texel.x,-texel.y)).rgb*0.20;
	blur += texture(scene,SCREEN_UV+vec2(-texel.x,texel.y)).rgb*0.20;
	ALBEDO = blur;
	ALPHA = 0.85*near_lens;
}
