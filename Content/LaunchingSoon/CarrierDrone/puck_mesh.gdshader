shader_type spatial;
uniform sampler2D albedoTexture : source_color;
uniform sampler2D scrollingTexture : source_color;
uniform float scrollSpeed = 1.0;
uniform vec4 colorA : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 colorB : source_color = vec4(0.0, 0.0, 1.0, 1.0);
uniform float colorLerpSpeed = 0.5;

void fragment() {
    vec4 albedo = texture(albedoTexture, UV);
    vec2 scrollingUV = UV;
    scrollingUV.x += TIME * scrollSpeed;
    vec4 scrollTex = texture(scrollingTexture, scrollingUV);
    float colorMix = sin(TIME * colorLerpSpeed) * 0.5 + 0.5;
    vec4 lerpedColor = mix(colorA, colorB, colorMix);
    ALBEDO = mix(albedo.rgb, lerpedColor.rgb * scrollTex.rgb, scrollTex.a);
}