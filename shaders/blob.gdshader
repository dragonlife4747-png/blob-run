shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.18, 0.88, 0.79);
uniform vec3 rim_color : source_color = vec3(1.0, 0.52, 0.18);
uniform float wobble : hint_range(0.0, 0.4) = 0.11;
uniform float flow_speed : hint_range(0.0, 8.0) = 2.3;
uniform float pinch : hint_range(0.0, 1.0) = 0.34;
uniform float stretch : hint_range(0.8, 1.6) = 1.18;

varying float v_n;
varying float v_yt;

float hash13(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.27, 0.39));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash13(i + vec3(0.0, 0.0, 0.0)), hash13(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(hash13(i + vec3(0.0, 1.0, 0.0)), hash13(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(hash13(i + vec3(0.0, 0.0, 1.0)), hash13(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(hash13(i + vec3(0.0, 1.0, 1.0)), hash13(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
		f.z);
}

void vertex() {
	vec3 dir = normalize(VERTEX);
	// teardrop silhouette: full width at the bottom, tapering into a tip on top
	float yt = clamp(VERTEX.y * 0.5 + 0.5, 0.0, 1.0);
	float taper = mix(1.0, pinch, smoothstep(0.30, 1.0, yt));
	vec3 p = VERTEX;
	p.xz *= taper;
	// shift so the drop's base sits exactly on the origin (scale/squash keep it planted)
	p.y = p.y * stretch + stretch;
	// flatten the base a little so the drop reads as planted, not hovering
	p.y = max(p.y, 0.11);

	// living jelly surface
	float t = TIME * flow_speed;
	float n1 = vnoise(dir * 2.2 + vec3(t * 0.7, t * 0.45, t * 0.6));
	float n2 = vnoise(dir * 5.2 - vec3(t * 1.1, t * 0.8, t * 0.9));
	float d = (n1 - 0.5) * wobble + (n2 - 0.5) * wobble * 0.35;
	p += dir * d;
	VERTEX = p;

	float tilt = mix(1.0, taper, smoothstep(0.30, 1.0, yt));
	NORMAL = normalize(vec3(NORMAL.x * tilt, NORMAL.y, NORMAL.z * tilt));
	v_n = n1;
	v_yt = yt;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.4);
	vec3 col = mix(base_color * 0.80, base_color * 1.24 + vec3(0.05), v_n);
	// liquid is denser (and deeper) at the belly, brighter towards the tip
	col *= mix(0.80, 1.10, smoothstep(0.02, 0.80, v_yt));
	col = mix(col, rim_color, fres * 0.58);

	// wet specular glint so the drop reads as glossy
	float hi = pow(max(dot(normalize(NORMAL), normalize(vec3(0.34, 0.72, 0.60))), 0.0), 26.0);
	float hi2 = pow(max(dot(normalize(NORMAL), normalize(vec3(-0.42, 0.38, 0.82))), 0.0), 40.0);

	ALBEDO = col;
	ROUGHNESS = 0.16;
	METALLIC = 0.0;
	EMISSION = rim_color * fres * 0.30
		+ base_color * 0.08
		+ vec3(1.0, 0.98, 0.95) * hi * 0.55
		+ vec3(0.85, 0.98, 1.0) * hi2 * 0.35;
}
