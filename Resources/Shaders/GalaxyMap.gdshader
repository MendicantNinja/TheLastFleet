shader_type spatial;

uniform sampler2D texture_albedo : source_color;
uniform float luminance_multiplier = 1.;

float luminance(vec3 color) {
	return min((0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b) * luminance_multiplier, 1);
	//return (color.r + color.g + color.b) / 3. * luminance_multiplier;
}

void fragment() {
	vec4 albedo_color = texture(texture_albedo, UV);
	
	ALBEDO = vec3(albedo_color.r, albedo_color.g, albedo_color.b);
	ALPHA = luminance(ALBEDO);
}