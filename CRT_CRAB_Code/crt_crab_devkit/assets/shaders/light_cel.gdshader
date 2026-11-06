shader_type spatial;
render_mode specular_disabled;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color, filter_nearest;
uniform bool textured = false;
uniform bool vertex_colors = false;
void fragment() {
    ALBEDO = base_color.rgb * (textured ? texture(base_texture, UV).rgb : vec3(1.0)) * (vertex_colors ? COLOR.rgb : vec3(1.0));
    ROUGHNESS = 0.92;
    METALLIC = 0.0;
    SPECULAR = 0.0;
}
void light() {
    float facing = max(dot(NORMAL, LIGHT), 0.0);
    float band = facing < 0.22 ? 0.0 : (facing < 0.65 ? 0.52 : 1.0);
    DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
