shader_type canvas_item;

// Radial speed streaks that fade in as the blob gains mass / speed.
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.42, 0.92, 1.0, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV - vec2(0.5);
	float r = length(uv) * 1.85;
	if (r < 0.34) {
		COLOR = vec4(0.0);
	} else {
		float ang = atan(uv.y, uv.x);
		float streak = sin(ang * 34.0 + sin(ang * 7.0) * 3.0);
		streak = pow(max(streak, 0.0), 6.0);
		float ring = smoothstep(0.34, 1.0, r);
		float a = strength * ring * (0.18 + streak * 0.55);
		COLOR = vec4(tint.rgb, a);
	}
}
