shader_type canvas_item;

uniform vec4 color_darkest: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_lightest: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float brightness : hint_range(0.0, 1.0); // Interpolation value (0 to 1)

void fragment() {
    vec4 final_color = mix(color_darkest, color_lightest, brightness);
    COLOR = final_color;
}
