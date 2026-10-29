shader_type canvas_item;

uniform float paper_strength : hint_range(0.0, 0.4) = 0.12;
uniform float pigment_strength : hint_range(0.0, 0.4) = 0.16;
uniform float edge_strength : hint_range(0.0, 0.6) = 0.18;
uniform float grain_scale : hint_range(1.0, 12.0) = 4.0;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise21(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
    vec4 source = texture(TEXTURE, UV) * COLOR;
    vec2 grain_pos = FRAGCOORD.xy * (grain_scale * 0.12);
    float paper = noise21(grain_pos);
    float pigment = noise21(grain_pos * 0.33 + vec2(17.0, 9.0));
    vec2 px = TEXTURE_PIXEL_SIZE;
    vec3 right_color = texture(TEXTURE, clamp(UV + vec2(px.x, 0.0), vec2(0.0), vec2(1.0))).rgb;
    vec3 down_color = texture(TEXTURE, clamp(UV + vec2(0.0, px.y), vec2(0.0), vec2(1.0))).rgb;
    float edge = clamp(length(source.rgb - right_color) + length(source.rgb - down_color), 0.0, 1.0);
    vec3 rgb = source.rgb * (1.0 + (paper - 0.5) * paper_strength);
    rgb *= 1.0 - pigment_strength * pigment * 0.25;
    rgb *= 1.0 - edge_strength * edge * 0.3;
    COLOR = vec4(clamp(rgb, 0.0, 1.0), source.a);
}
