// Painted sky: a soft warm-to-blue gradient with large, layered clouds drifting slowly.
// Value-noise clouds only (no volumetrics), so it stays cheap on the Compatibility renderer.
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.42, 0.62, 0.88);
uniform vec3 horizon_color : source_color = vec3(0.98, 0.86, 0.72);
uniform vec3 ground_color : source_color = vec3(0.72, 0.78, 0.62);
uniform vec3 cloud_light : source_color = vec3(1.0, 0.97, 0.9);
uniform vec3 cloud_shade : source_color = vec3(0.78, 0.8, 0.92);
uniform float cloud_speed = 0.006;
uniform float cloud_cover = 0.52;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = EYEDIR;
	float up = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(horizon_color, top_color, pow(up, 0.55));
	if (d.y < 0.0) {
		col = mix(horizon_color, ground_color, clamp(-d.y * 4.0, 0.0, 1.0));
	} else {
		vec2 uv = d.xz / (d.y + 0.22) * 0.9 + vec2(TIME * cloud_speed, TIME * cloud_speed * 0.3);
		float n = fbm(uv);
		float c = smoothstep(cloud_cover, cloud_cover + 0.2, n);
		float shade = smoothstep(cloud_cover, cloud_cover + 0.35, fbm(uv + vec2(0.06, 0.04)));
		vec3 cloud = mix(cloud_shade, cloud_light, shade);
		col = mix(col, cloud, c * smoothstep(0.0, 0.15, d.y) * 0.92);
	}
	COLOR = col;
}
