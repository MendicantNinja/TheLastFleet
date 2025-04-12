shader_type canvas_item;
uniform sampler2D shield_noise_texture;

uniform vec4 shield_color = vec4(0.0, 0.4, 1.0, 1.0);
uniform vec2 texture_size = vec2(1, 1);       // The size of the shield texture in pixels
uniform float shield_px_width = 2.00;

uniform float circle_radius = .5;

uniform vec2 ellipse_radius = vec2(.3035, .5);


/*
< 0 → Inside the circle
= 0 → On the circle’s edge
> 0 → Outside the circle
*/

float sdfEllipse(vec2 p, vec2 r) {
    vec2 d = abs(p) / r;  // Normalize position by ellipse radii
    return (length(d) - 1.0) * min(r.x, r.y);
}

float sdfCircle(vec2 p, float r) {
 return length(p) - r; // Absolute = give the magnitude
// Not absolute = normal signed distance function. Negative inside, zero on surface, positive outside.
// Nature of our circle calculation is that everything will end up negative
}

void fragment() {
	// UV Ranges from -1 to 1
	// Shield.x and Shield.y are ranges within this range. (.5, .5) (if AABB is square)
	// -.5 is the center. 0 is the edge.
	//float distance_from_center = sdfEllipse(UV, ellipse_radius);
	float dist = sdfCircle(UV, .5); //
	float shield_width = shield_px_width / circle_radius; // shield_width in UV for the currently sized ship
	float alpha = .5;
	if (dist > -shield_width) { // 0.00 - .0.02 or so
		vec3 edge_rgb = mix(vec3(1.0), shield_color.rgb, 0.7); // adjust 0.5 as needed
		COLOR = vec4(edge_rgb, 0.5);
	}
	else { // 0.0 to -.48 or so
		vec2 sample_uv = UV * 0.5 + vec2(0.5);
		float noise = texture(shield_noise_texture, sample_uv).r;
		//alpha = noise;
		alpha -= smoothstep(0.0, -.5, dist);
		COLOR = vec4(shield_color.rgb, alpha);


	}

	//float alpha = 1.0 - smoothstep(0.4, 0.5, dist); // soft edge falloff

}
