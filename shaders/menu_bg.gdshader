shader_type canvas_item;
render_mode unshaded;

uniform vec3 c_top : source_color = vec3(0.027, 0.043, 0.118);
uniform vec3 c_bot : source_color = vec3(0.114, 0.169, 0.376);
uniform vec3 glow_a : source_color = vec3(0.208, 0.902, 1.0);
uniform vec3 glow_b : source_color = vec3(1.0, 0.302, 0.561);
uniform float intensity = 1.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	vec3 col = mix(c_top, c_bot, smoothstep(0.0, 1.0, uv.y));
	float t = TIME * 0.09;
	vec2 p1 = vec2(0.16 + 0.09 * sin(t * 1.7), 0.14 + 0.06 * cos(t * 1.3));
	vec2 p2 = vec2(0.88 + 0.08 * cos(t * 1.1), 0.34 + 0.07 * sin(t * 0.9));
	vec2 q = uv * vec2(0.62, 1.0);
	float d1 = distance(q, p1 * vec2(0.62, 1.0));
	float d2 = distance(q, p2 * vec2(0.62, 1.0));
	col += glow_a * 0.20 * smoothstep(0.52, 0.0, d1);
	col += glow_b * 0.13 * smoothstep(0.46, 0.0, d2);

	vec2 g = uv * vec2(26.0, 44.0);
	float dd = length(fract(g) - 0.5) * 2.0;
	col += vec3(0.40, 0.60, 0.90) * smoothstep(1.0, 0.86, dd) * 0.018;

	float vig = smoothstep(1.05, 0.30, length((uv - 0.5) * vec2(1.0, 1.05)));
	col *= mix(0.66, 1.0, vig);
	col += (hash21(uv * 640.0 + TIME) - 0.5) * 0.014;
	COLOR = vec4(col * intensity, 1.0);
}
