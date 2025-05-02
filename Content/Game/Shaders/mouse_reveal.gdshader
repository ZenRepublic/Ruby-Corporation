shader_type canvas_item;

uniform float radius = 0.3; // Radius of the circle
uniform float feather = 0.05; // Feathering of the circle's edge

uniform vec2 center = vec2(0.5, 0.5); // Center (Adjust to move the circle around)

float circle_mask(vec2 _uv, vec2 _center, float _radius, float _feather) {
    float dist = length(_uv - _center); // Distance from current pixel to the center
    return smoothstep(_radius, _radius - _feather, dist); // Smooth transition
}

void fragment() {
    float mask = circle_mask(UV, center, radius, feather); // Calculate the mask

    vec4 tex_color = texture(TEXTURE, UV); // Sample the texture color
    tex_color.a *= 1.0 - mask; // Apply the mask to the alpha channelk

    COLOR = tex_color; // Set the final color
}
