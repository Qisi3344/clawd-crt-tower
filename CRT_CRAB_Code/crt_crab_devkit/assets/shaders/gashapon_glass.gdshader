shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
uniform vec4 glass_color : source_color = vec4(0.8902,0.8627,0.9216,1.0);
void fragment() {
    float edge = pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),3.0);
    ALBEDO = glass_color.rgb;
    ALPHA = mix(0.10,0.42,edge);
    ROUGHNESS = 0.08;
    SPECULAR = 0.45;
}
