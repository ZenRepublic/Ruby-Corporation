shader_type canvas_item;

// Ranges from 0 to 1 over the course of the transition.
// We use this to actually animate the shader.
uniform vec3 start_color : source_color;
uniform vec3 end_color :source_color;
uniform float progress : hint_range(0, 1);
// Size of each diamond, in pixels.
uniform float diamondPixelSize = 10.0;
uniform bool forward = true;

void fragment() {
	float xFraction = fract(FRAGCOORD.x / diamondPixelSize);
	float yFraction = fract(FRAGCOORD.y / diamondPixelSize);
	float xDistance = abs(xFraction - 0.5);
	float yDistance = abs(yFraction - 0.5);

	float diamond_position = xDistance + yDistance + UV.x + UV.y;

	float adjusted_progress = progress;
	if (!forward) {
		adjusted_progress = 1.0-progress;
	}
	float final_progress = adjusted_progress * 3.0;

	if (forward && diamond_position > final_progress) {
		discard;
	}
	else if(!forward && diamond_position < final_progress) {
		discard;
	}

	COLOR.rgb = mix(start_color,end_color,progress);
}
