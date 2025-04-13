shader_type spatial;
render_mode unshaded;

uniform sampler3D cloud_noise_texture;
uniform float cloud_scale : hint_range(0.001, 5.0) = 1.0;
uniform float cloud_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float cloud_threshold_multiplier: hint_range(0.00, 10.00) = 0.05;
uniform int max_steps : hint_range(1, 200) = 64;
uniform float step_size : hint_range(0.01, 0.5) = 0.1;
uniform float cloud_scroll_speed : hint_range(-1.0, 1.0) = 0.5;
uniform vec3 minBounds = vec3(-1.0, -1.0, -1.0);
uniform vec3 maxBounds = vec3(1.0, 1.0, 1.0);

uniform sampler3D detail_noise_texture;
uniform float detail_intensity = 0.5;

float sample_detail_noise(vec3 position) {
    return texture(detail_noise_texture, position).r;
}

float sample_cloud(vec3 position) {
    vec3 offsetPos = position + cloud_scroll_speed * TIME;
    float main_cloud = texture(cloud_noise_texture, offsetPos).r;
    float detail = sample_detail_noise(position * 10.0);  // 10.0 is an arbitrary value for higher frequency
    return mix(main_cloud, detail, detail_intensity);
}

float raymarch(vec3 ro_model, vec3 rd_model, vec2 intersections) {
    float total_density = 0.0;
    float t = intersections.x;  // start from the entry point
    float max_t = intersections.y;  // march up to the exit point

    for (int i = 0; i < max_steps && t < max_t; i++) {
        vec3 pos_model = ro_model + t * rd_model;
        float density = sample_cloud(pos_model * cloud_scale);
        density = smoothstep(cloud_threshold - 0.05, cloud_threshold + cloud_threshold_multiplier, density);
        total_density += density * step_size;
        t += step_size;
    }
    return total_density;
}


// Return both entry and exit intersections with the mesh
vec2 getRayIntersections(vec3 ro, vec3 rd) {
    vec3 t1 = (minBounds - ro) / rd;
    vec3 t2 = (maxBounds - ro) / rd;

    vec3 tmin = min(t1, t2);
    vec3 tmax = max(t1, t2);

    float t_near = max(max(tmin.x, tmin.y), tmin.z);
    float t_far = min(min(tmax.x, tmax.y), tmax.z);

    if (t_near > t_far || t_far < 0.0) {
        return vec2(-1.0, -1.0); // No intersection
    }

    return vec2(t_near, t_far);
}

void fragment() {
    vec3 ro_world = INV_VIEW_MATRIX[3].xyz;
    vec4 clipPos = vec4((FRAGCOORD.xy / VIEWPORT_SIZE.xy) * 2.0 - 1.0, FRAGCOORD.z, 1.0);
    vec4 viewPos = INV_PROJECTION_MATRIX * clipPos;
    vec3 rd_world = normalize(viewPos.xyz / viewPos.w);
    rd_world = mat3(INV_VIEW_MATRIX) * rd_world;

    vec2 intersections = getRayIntersections(ro_world, rd_world);

    // Check if there's no intersection
    if (intersections.x == -1.0) {
        discard;
    }

    vec3 ro_model = mat3(inverse(MODEL_MATRIX)) * (ro_world - MODEL_MATRIX[3].xyz);
    vec3 rd_model = mat3(inverse(MODEL_MATRIX)) * rd_world;

    float cloud_intensity = raymarch(ro_model, rd_model, intersections);

    ALBEDO = vec3(0.8, 0.8, 0.9) * cloud_intensity;
    ALPHA = cloud_intensity;
}