shader_type canvas_item;
uniform sampler2D shield_noise_texture;

uniform vec4 shield_color = vec4(0.0, 0.4, 1.0, 1.0);
uniform vec2 texture_size = vec2(1, 1);       // The size of the shield texture in pixels
uniform float shield_px_width = 2.00;

uniform float circle_radius = .5;

uniform vec2 ellipse_radius = vec2(.3035, .5);

//uniform vec2 hit_pos = vec2(-1000.0); // Default off-screen
//uniform float hit_radius = 0.0;   // 500 = maximum radius
//0 = no radius, no damage, full transparency.
const int MAX_HITS = 32;
uniform vec2 hit_positions[MAX_HITS];
uniform float hit_radii[MAX_HITS];
uniform float hit_timers[MAX_HITS];
uniform int hit_count; // how many active hits are currently in the list

float sdfEllipse(vec2 p, vec2 r) {
    vec2 d = abs(p) / r;  // Normalize position by ellipse radii
    return (length(d) - 1.0) * min(r.x, r.y);
}

float sdfCircle(vec2 p, float r) {
 return length(p) - r; // Absolute = give the magnitude
// Not absolute = normal signed distance function. Negative inside, zero on surface, positive outside.
// Nature of our circle calculation is that everything inside the circle will end up negative
}

void fragment() {
	// UV is entire polygon size (100, 100) for the ShiedVisuals debug squaretexture.
	// But UV goes to between -1 and 1 in-game with our circle/an actual polygon. Perhaps due to the place holder texture?
	// Confusing and a pain in the ass. I know. Blame Godot.
	// Shield.x and Shield.y are ranges within this range. (.5, .5) (if AABB is square)
	vec4 base_color;
	float dist = sdfCircle(UV, .5); //
	// dist of -.5 is the center of our shield. 0 is the edge of the shield. positive is outside
	float shield_width = shield_px_width / circle_radius; // shield_width in UV for the currently sized ship
	float alpha = .5;
	if (dist > -shield_width) { // 0.00 - .0.02 or so
		vec3 edge_rgb = mix(vec3(1.0), shield_color.rgb, 0.5); // adjust last float as needed. higher = more shield color
		base_color = vec4(edge_rgb, 0.5);
	}

	else { // 0.0 to -.48 or so. The rest of the shield.
		vec2 sample_uv = UV * 0.5 + vec2(0.5);
		float noise = texture(shield_noise_texture, sample_uv).r;
		alpha -= smoothstep(0.0, -.5, dist);
		base_color = vec4(shield_color.rgb, alpha);
	}

	for (int i = 0; i < hit_count; i++) {
		vec2 offset = UV - hit_positions[i];
		float damage_dist = sdfCircle(offset, hit_radii[i] * 0.5);
		if (damage_dist < 0.0) {
			float fade = smoothstep(0.0, 1.0, hit_timers[i]);
			vec4 flash_color = vec4(1, 1, 1, .7); // bright white
			base_color = mix(base_color, flash_color, fade); // blend on top of existing
		}
	}
	COLOR = base_color;
	}
	/*
	if (UV.x > 0.0 && UV.x < 1.0) {
		COLOR = vec4(255, 255, 255, 255);
	}
	else if (UV.x < 0.0 && UV.x > -1.0)   {
		COLOR = vec4(0, 0, 0, 255);
	}
	*/