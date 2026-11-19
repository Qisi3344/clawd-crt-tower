shader_type spatial;
render_mode specular_disabled, ambient_light_disabled;
// Nilo's MIT lighting example: smooth cel thresholds, a colored indirect floor,
// and bounded lighting. Godot implementation; see docs/cel_shading_evidence/references/ for sources.
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color, filter_nearest;
uniform bool textured = false;
uniform bool vertex_colors = false;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);
uniform vec4 shade_color : source_color = vec4(0.63, 0.57, 0.76, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 0.90, 0.75, 1.0);
uniform float indirect_strength : hint_range(0.0, 1.0) = 0.60;
uniform float highlight_strength : hint_range(0.0, 0.5) = 0.075;
uniform float rim_strength : hint_range(0.0, 0.5) = 0.08;
uniform bool double_sided = false;
#include "res://assets/shaders/club_finish.gdshaderinc"
uniform float patina_strength = 0.86;
uniform vec3 spill_center;
uniform vec4 spill_right;
uniform vec4 spill_up;
uniform vec3 spill_color;
uniform bool picture_enabled = false;
uniform sampler2D picture : source_color, filter_linear;
uniform vec4 picture_region = vec4(0.0,0.0,1.0,1.0);
uniform vec3 overhead_base;
uniform vec4 overhead_foot;
varying vec3 phosphor_color;
varying vec3 hall_position;
varying vec3 mesh_normal;
void vertex() {
    hall_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    mesh_normal = NORMAL;
    phosphor_color = spill_color;
    if (picture_enabled) {
        vec3 sample_color = vec3(0.0);
        for (int i=0;i<9;i++) {
            vec2 uv = (vec2(float(i%3),float(i/3))+vec2(0.43,0.57))/3.0;
            sample_color += textureLod(picture,picture_region.xy+uv*picture_region.zw,0.0).rgb;
        }
        sample_color /= 9.0;
        phosphor_color = clamp(spill_color*0.36+sample_color*2.8,vec3(0.0),vec3(0.95));
    }
}
void fragment() {
    ALBEDO = base_color.rgb * (textured ? texture(base_texture, UV * uv_scale.xy + uv_offset.xy).rgb : vec3(1.0)) * (vertex_colors ? COLOR.rgb : vec3(1.0));
    ALBEDO = club_worn(club_grade(ALBEDO,patina_strength),hall_position,mesh_normal,patina_strength);
    if (double_sided && !FRONT_FACING) NORMAL = -NORMAL;
    // A single indirect term, never added once per local light.
    EMISSION = ALBEDO * shade_color.rgb * indirect_strength + patina_strength*club_reflection(NORMAL,VIEW,ALBEDO);
    if (spill_right.w>0.0) {
        vec3 d = hall_position-spill_center;
        vec3 local = vec3(dot(d,spill_right.xyz),dot(d,spill_up.xyz),dot(d,cross(spill_right.xyz,spill_up.xyz)));
        EMISSION += phosphor_color*club_screen_spill(local,vec2(spill_right.w,spill_up.w))*(0.53+0.55*ALBEDO);
    }
    if (overhead_foot.z>0.0) {
        vec3 d = hall_position-overhead_base;
        vec2 axis = overhead_foot.xy;
        vec2 p = abs(vec2(dot(d.xz,axis),dot(d.xz,vec2(-axis.y,axis.x))));
        float contact = exp(-3.4*length(max(p-overhead_foot.zw,vec2(0.0)))-3.0*abs(d.y));
        contact *= smoothstep(-0.1,0.65,(INV_VIEW_MATRIX*vec4(NORMAL,0.0)).y);
        ALBEDO *= 1.0-0.28*contact;
        EMISSION *= 1.0-0.36*contact;
    }
    ROUGHNESS = 0.92;
    METALLIC = 0.0;
    SPECULAR = 0.0;
}
void light() {
    float facing = dot(NORMAL, LIGHT);
    // Small transition widths soften subpixel flicker, while retaining flat bands.
    float middle = smoothstep(0.16, 0.20, facing);
    float bright = smoothstep(0.60, 0.64, facing);
    vec3 ramp = mix(shade_color.rgb * 0.24, shade_color.rgb * 0.66, middle);
    ramp = mix(ramp, vec3(0.94), bright);
    vec3 energy = clamp(ATTENUATION * LIGHT_COLOR / PI, vec3(0.0), vec3(1.25));
    // Strongest-light composition prevents the many CRT lights washing out bands.
    DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, ramp * energy);
    float gloss = pow(max(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0), 48.0);
    float spec = smoothstep(0.48, 0.54, gloss) * highlight_strength;
    float rim = smoothstep(0.72, 0.78, 1.0 - max(dot(NORMAL, VIEW), 0.0));
    rim *= smoothstep(0.15, 0.45, facing) * rim_strength;
    SPECULAR_LIGHT = max(SPECULAR_LIGHT, highlight_color.rgb * energy * (spec + rim));
}
