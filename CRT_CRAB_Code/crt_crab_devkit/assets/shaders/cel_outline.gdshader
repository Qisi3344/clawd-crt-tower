shader_type spatial;
render_mode cull_front, unshaded, depth_draw_never;
// Adapted from Rafael Bordoni's MIT Godot 4 cel outline, with normal-matrix,
// zero-vector protection, reference-resolution scaling and world-width limits.
// Copyright (c) 2023 Rafael de Lima Bordoni. License in docs/cel_shading_evidence/references/.
uniform vec4 outline_color : source_color = vec4(0.075, 0.055, 0.115, 1.0);
uniform float outline_width : hint_range(0.0, 3.0) = 1.15;
uniform float max_world_width = 0.025;
varying float hull_facing;
void vertex() {
    vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    vec3 view_normal = MODELVIEW_NORMAL_MATRIX * NORMAL;
    hull_facing = dot(normalize(view_normal), normalize(-view_position.xyz));
    // Offset away from the camera in view space. Clip-space depth offsets change
    // meaning with reverse-Z and grow with distance, covering thin/open surfaces.
    view_position.z -= 0.003;
    vec4 clip_position = PROJECTION_MATRIX * view_position;
    vec2 projected_normal = (mat3(PROJECTION_MATRIX) * view_normal).xy;
    vec2 direction = projected_normal / max(length(projected_normal), 0.0001);
    float pixel_world = 2.0 * max(-view_position.z, 0.01) / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
    float width = min(outline_width * VIEWPORT_SIZE.y / 900.0, max_world_width / pixel_world);
    clip_position.xy += direction * (2.0 * width / VIEWPORT_SIZE) * clip_position.w;
    POSITION = clip_position;
}
void fragment() {
    // Degenerate pole triangles and split normals must not ink the front surface.
    if (hull_facing > 0.05) discard;
    ALBEDO = outline_color.rgb;
}
