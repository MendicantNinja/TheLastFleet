shader_type canvas_item;

uniform vec4 hologram_color = vec4(0.0, .2, 1.0, 1.0);
uniform float emission_strength : hint_range(0.0, 5.0) = 1.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.02;
uniform float flicker_speed : hint_range(0.1, 10.0) = 2.0;
uniform float distortion_amount : hint_range(0.0, 1) = .1;
uniform float fresnel_power : hint_range(1.0, 500.0) = 50;
uniform float alpha_strength : hint_range(0.0, 1.0) = .7; // Transparency control

void fragment() {
    vec2 uv = UV;

    // Scanline Effect
    float scanline = sin(uv.y * 100.0) * scanline_intensity;

    // Flickering Effect
    float flicker = sin(TIME * flicker_speed) * 0.05;

    // Fresnel Glow Effect
    float fresnel = pow(1.0 - uv.y, fresnel_power);
	float fresnel_bottom = pow(uv.y, fresnel_power);
    float fresnel_left = pow(1.0 - uv.x, fresnel_power);
	float fresnel_right = pow(uv.x, fresnel_power);

    //float fresnel_y = min(uv.y, 1.0 - uv.y);
    //float fresnel = pow(min(fresnel_x, fresnel_y), fresnel_power);
    // Distortion Effect
    uv.x += sin(uv.y * 10.0 + TIME * 2.0) * distortion_amount;

    // Final Color Composition
   vec4 final_color = hologram_color + vec4(scanline + flicker + fresnel+fresnel_left+fresnel_bottom+fresnel_right, scanline + flicker + fresnel+fresnel_left+fresnel_bottom+fresnel_right, scanline + flicker + fresnel+fresnel_left+fresnel_bottom+fresnel_right, 1.0);

	// Apply Alpha Transparency (More transparent toward center)
    final_color.a = alpha_strength;

    // Apply Emission and Output
    COLOR = final_color * emission_strength;
}
