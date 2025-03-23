shader_type canvas_item;

uniform sampler2D fog_texture; // Reveal texture to modify fog
uniform vec4 fog_color = vec4(0.0, 0.0, 0.0, 0.8); // Default fog color

void fragment() {
    vec4 fog_tex = texture(fog_texture, UV);
    float reveal = fog_tex.r; 

    // Lerp between fog color and transparency based on revealed areas
    COLOR = mix(fog_color, vec4(0.0), reveal);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
