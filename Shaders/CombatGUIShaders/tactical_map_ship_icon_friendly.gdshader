shader_type canvas_item;

uniform float glow_intensity : hint_range(0.0, 2.0) = 2.2;
uniform float flicker_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float grid_scale : hint_range(0.1, 5.0) = 20.0;
uniform vec4 hologram_color = vec4(0.0, 1.0, 0.3, 1.0); // Default cyan
uniform float time_speed : hint_range(0.0, 5.0) = 5.0;

void fragment() {

}