shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
uniform vec4 glass_color : source_color = vec4(0.8902,0.8627,0.9216,1.0);
void fragment() {
    float edge = pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),2.5);
    ALBEDO = glass_color.rgb;
    ALPHA = mix(0.08,0.48,edge);
    ROUGHNESS = 0.06;
    SPECULAR = 0.60;
}
