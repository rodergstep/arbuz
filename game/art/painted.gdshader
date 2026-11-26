// The shared painted look (docs/design-system.md, Art direction): toon light in soft bands,
// shadows tinted cool blue-violet instead of black, a vertical painted gradient on every
// object, an optional low-frequency colour wash for big surfaces, a gentle rim light and an
// optional wind sway. One cheap shader for everything, so it holds 30 fps on the Intel MacBook.
shader_type spatial;
render_mode cull_back;

uniform vec4 base_color : source_color = vec4(1.0);
// shade.cool from the design system
uniform vec4 shade_color : source_color = vec4(0.486, 0.525, 0.722, 1.0);
// darker at the foot, lighter at the top (object space)
uniform float gradient = 0.22;
uniform float gradient_scale = 0.35;
// colour wash in world space for large surfaces such as the ground (0 = off)
uniform float variation = 0.0;
uniform float rim_strength = 0.22;
// wind sway for leaves and grass (0 = still); stronger higher up
uniform float sway = 0.0;

varying float v_height;
varying vec3 v_world;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	v_height = VERTEX.y;
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (sway > 0.0) {
		float bend = max(VERTEX.y, 0.0);
		float wave = sin(TIME * 1.4 + world.x * 0.35 + world.z * 0.2) + 0.4 * sin(TIME * 2.3 + world.z * 0.6);
		VERTEX.x += wave * sway * bend;
		VERTEX.z += wave * sway * 0.4 * bend;
	}
	v_world = world;
}

void fragment() {
	float g = clamp(v_height * gradient_scale + 0.5, 0.0, 1.0);
	vec3 col = base_color.rgb * mix(1.0 - gradient, 1.0 + gradient * 0.4, g);
	if (variation > 0.0) {
		float n = noise(v_world.xz * 0.08) * 0.7 + noise(v_world.xz * 0.31) * 0.3;
		col *= 1.0 + (n - 0.5) * variation;
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// two soft steps: shade -> half -> full light
	float band = smoothstep(-0.05, 0.08, ndl) * 0.55 + smoothstep(0.35, 0.5, ndl) * 0.45;
	float lit = band * ATTENUATION;
	vec3 tint = mix(shade_color.rgb * 0.6, vec3(1.0), lit);
	DIFFUSE_LIGHT += tint * LIGHT_COLOR / PI;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * rim_strength * band;
	DIFFUSE_LIGHT += rim * LIGHT_COLOR / PI;
}
