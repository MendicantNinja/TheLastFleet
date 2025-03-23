shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 2.0) = 2.0;
uniform float flicker_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float grid_scale : hint_range(0.1, 5.0) = 20.0;
uniform vec4 hologram_color = vec4(1.0, .5, 0.0, 1.0); // Default cyan
uniform float time_speed : hint_range(0.0, 5.0) = 5.0;

void fragment() {
    //vec4 tex_color = texture(TEXTURE, UV);
    //// Basic flicker for brightness modulation
    //float flicker_effect = 1.0 + flicker_intensity * sin(TIME * 8.0);
    //
    //// Create dynamic grid
    //vec2 grid_uv = UV * grid_scale;
    //vec2 grid = abs(fract(grid_uv - 0.5) - 0.5) / fwidth(grid_uv);
    //float grid_mask = 1.0 - min(grid.x, grid.y);
    //
    //// Combine grid and hologram effect with flicker
    //vec3 holo_color = hologram_color.rgb * flicker_effect * glow_intensity;
    //vec3 final_color = mix(tex_color.rgb, holo_color, grid_mask * flicker_effect * 0.7);
    //
    //COLOR = vec4(final_color, tex_color.a);
}