shader_type canvas_item;

uniform vec4 shield_color = vec4(0.0, 0.4, 1.0, 1.0);
uniform vec2 ellipse_radius = vec2(.607, 1);
/*
< 0 → Inside the circle
= 0 → On the circle’s edge
> 0 → Outside the circle
*/

float sdfEllipse(vec2 p, vec2 r) {
    vec2 d = abs(p) / r;  // Normalize position by ellipse radii
    return (length(d) - 1.0) * min(r.x, r.y);
}

void fragment() {
	COLOR = vec4(UV, 0.0, 1.0); 
	/*
	vec2 centeredUV = UV * 2.0 - 1.0;
	float distance_from_center = sdfEllipse(centeredUV, ellipse_radius);
	float alpha = clamp(distance_from_center * 2.0, 0.0, 1.0);
	COLOR = vec4(shield_color.rgb, alpha); 
	if (UV.x < 0.05) {
		COLOR.a = .4;
	}
	*/
    //COLOR = shield_color;
    //COLOR.a *= alpha;  // Multiply the original alpha by the computed fade value
}

