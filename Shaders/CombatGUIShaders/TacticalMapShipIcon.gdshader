shader_type canvas_item;

uniform vec4 hologram_color = vec4(.5, 1.0, .6, 1.0); // Cyan color
uniform float speed = 1.5;        // Speed of the scan lines
uniform float glow_intensity = 0.4; // Intensity of the glow
uniform float noise_intensity = 0.4; // Flicker strength

void fragment() {
    // Get UV coordinates
    vec2 uv = UV;
    
    // Create scan lines
    float scan_lines = sin((uv.y + TIME * speed) * 200.0) * 0.1;

    // Add random noise flicker
    float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    noise = mix(0.5, 1.0, noise) * noise_intensity;

    // Combine scan lines and noise for distortion
    float hologram_effect = scan_lines + noise;
    
    // Sample the texture with the holographic tint
    vec4 tex_color = texture(TEXTURE, uv);
    tex_color.rgb *= hologram_color.rgb;

    // Apply the glow effect
    float glow = smoothstep(0.2, 0.8, tex_color.a) * glow_intensity;

    // Final color with distortion and glow applied
    COLOR = tex_color + hologram_effect * glow;
    COLOR.a = tex_color.a; // Preserve alpha for transparency
}