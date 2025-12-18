shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

// Simple animated water (no textures) using a few sine waves + a Fresnel-ish color blend.
uniform vec4 deep_color : source_color = vec4(0.03, 0.05, 0.08, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.08, 0.12, 0.16, 1.0);

uniform float wave_amplitude = 0.35;
uniform float wave_scale = 0.08;
uniform float wave_speed = 1.2;

void vertex() {
	// World position so waves are stable even if the water mesh is moved/scaled.
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME;

	float h1 = sin(wp.x * wave_scale + t * wave_speed);
	float h2 = cos(wp.z * (wave_scale * 1.37) + t * (wave_speed * 0.83));
	float h3 = sin((wp.x + wp.z) * (wave_scale * 0.7) + t * (wave_speed * 1.15));

	float h = (h1 * 0.55 + h2 * 0.35 + h3 * 0.25) * wave_amplitude;
	VERTEX.y += h;

	// Approximate normal from analytical derivatives (good enough for highlights).
	float dx = wave_amplitude * wave_scale * (
		cos(wp.x * wave_scale + t * wave_speed) * 0.55 +
		cos((wp.x + wp.z) * (wave_scale * 0.7) + t * (wave_speed * 1.15)) * 0.25 * 0.7
	);

	float dz = wave_amplitude * wave_scale * (
		(-sin(wp.z * (wave_scale * 1.37) + t * (wave_speed * 0.83)) * 0.35 * 1.37) +
		cos((wp.x + wp.z) * (wave_scale * 0.7) + t * (wave_speed * 1.15)) * 0.25 * 0.7
	);

	NORMAL = normalize(vec3(-dx, 1.0, -dz));
}

void fragment() {
	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, 5.0);

	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, 0.35 + fresnel * 0.65);
	ROUGHNESS = 0.10 + (1.0 - fresnel) * 0.25;
	SPECULAR = 0.70;
}





