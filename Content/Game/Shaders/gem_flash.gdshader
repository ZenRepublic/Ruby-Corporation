shader_type canvas_item;

uniform vec4 shine_color : source_color;
uniform float flash_value : hint_range(0.0, 1.0, 0.1) = 0;

uniform float shine_progress : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float shine_size : hint_range(0.01, 1.0, 0.01) = 0.1;
uniform float shine_angle : hint_range(0.0, 89.9, 0.1) = 45.0;

float scale(float value, float inMin, float inMax, float outMin, float outMax) {
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
}

void fragment() {
//	handle flashing
    vec4 texture_color = texture(TEXTURE, UV);
    vec4 flash_color = mix(texture_color, shine_color, flash_value);
//	handle shine strip
	COLOR = texture(TEXTURE, UV);
	float slope = tan(radians(shine_angle));
	float progress = scale(shine_progress, 0.0, 1.0, -1.0 - shine_size - shine_size * slope, 1.0 * slope);
    float shine = step(slope * UV.x - UV.y, progress + shine_size + shine_size * slope) - step(slope * UV.x - UV.y, progress);

	vec4 shine_color_applied = mix(flash_color, shine_color, shine * shine_color.a);
	COLOR = shine_color_applied;
	COLOR.a = texture_color.a;
}