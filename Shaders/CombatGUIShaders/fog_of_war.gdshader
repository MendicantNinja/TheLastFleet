shader_type canvas_item;
//render_mode light_only;
uniform sampler2D noise_texture: repeat_enable, filter_nearest; // Texture to modify fog
uniform sampler2D visibility_texture;

uniform float density: hint_range(0.0, 1.0) = 1.0;
 // If 1.0, do not reveal. If 0, do!)
uniform vec2 speed = vec2(1, 1);
void fragment() {
	if (texture(visibility_texture, UV).r > 0.1) {
        COLOR = vec4(1, 1, 1, 0); // Make the fog transparent
	}
	else {
		vec2 uv = UV + speed * TIME;
		float noise = texture(noise_texture, UV).r;
		// Apply the fog
		COLOR.a = noise;
	}
}