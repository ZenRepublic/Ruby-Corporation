shader_type canvas_item;

uniform sampler2D dissolve_pattern;
uniform float dissolve_progress : hint_range(0.0, 1.0, 0.01) = 0;
uniform vec4 tint: source_color;

void fragment() {
	COLOR = texture(TEXTURE,UV) * tint;
	float pattern_val = texture(dissolve_pattern, UV).r;
	COLOR.a *= step(dissolve_progress,pattern_val);
}
