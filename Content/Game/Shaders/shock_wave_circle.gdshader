shader_type canvas_item;

uniform vec2 center;
uniform float force;
uniform float size;
uniform float thickness;

uniform sampler2D SCREEN_TEXTURE:hint_screen_texture;

void fragment() {
	float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;

	vec2 scaledUV = (SCREEN_UV - vec2(0.5, 0.0)) / vec2(ratio, 1.0) + vec2(0.5, 0.0);
	float blob = 1.0 - smoothstep(size-0.1,size,length(scaledUV - center));
	float donutMask = blob * smoothstep(size-0.1-thickness,size-thickness,length(scaledUV - center));
	vec2 disp = normalize(scaledUV - center) * force * donutMask;
	COLOR = vec4(SCREEN_UV-disp,0.0,1.0);
	COLOR = texture(SCREEN_TEXTURE,SCREEN_UV-disp);
	//COLOR.rgb = vec3(donutMask*force);
}
