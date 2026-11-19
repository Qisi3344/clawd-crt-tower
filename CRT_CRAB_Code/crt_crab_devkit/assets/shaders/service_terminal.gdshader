shader_type spatial;
render_mode unshaded, shadows_disabled;
uniform sampler2D atlas : source_color, filter_linear_mipmap;
void fragment() {
	vec2 uv = vec2(3.0,0.0)+mix(vec2(0.025),vec2(0.975),UV);
	ALBEDO = texture(atlas,uv/vec2(4.0,2.0)).rgb*0.80;
}
