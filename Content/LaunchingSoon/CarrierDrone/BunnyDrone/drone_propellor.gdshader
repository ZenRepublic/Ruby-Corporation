shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D texture_albedo : source_color;
uniform float alpha : hint_range(0, 1) = 0.5;
uniform float rotation_speed : hint_range(-15.0, 15.0) = 1.0;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);

void vertex() {
	// Pass UV coordinates to fragment shader
	UV = UV * uv_scale + uv_offset;
}

void fragment() {
	// Calculate rotation based on time
	float time = TIME * rotation_speed;
	float s = sin(time);
	float c = cos(time);

	// Create rotation matrix
	mat2 rotation_matrix = mat2(vec2(c, -s), vec2(s, c));

	// Center UVs (0.5, 0.5 is center)
	vec2 centered_uv = UV - vec2(0.5, 0.5);

	// Apply rotation
	vec2 rotated_uv = rotation_matrix * centered_uv;

	// Move back to original position
	rotated_uv += vec2(0.5, 0.5);

	// Sample the texture with rotated UVs
	vec4 albedo_tex = texture(texture_albedo, rotated_uv);

	// Apply transparency
	ALBEDO = albedo_tex.rgb;
	ALPHA = albedo_tex.a * alpha;

	// Optional: add metallic/roughness/etc if needed
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
}