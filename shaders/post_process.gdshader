shader_type canvas_item;

// Full-screen post-processing stack:
//   - Bloom (box-blur on mip level, threshold extracted)
//   - Chromatic aberration (radial RGB split)
//   - Vignette
//   - Film grain
//   - Subtle scanlines

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float chromatic_aberration : hint_range(0.0, 10.0) = 2.0;
uniform float vignette_strength    : hint_range(0.0, 2.0) = 1.1;
uniform float vignette_radius      : hint_range(0.0, 2.0) = 0.85;
uniform float grain_strength       : hint_range(0.0, 1.0) = 0.06;
uniform float bloom_strength       : hint_range(0.0, 3.0) = 0.9;
uniform float bloom_threshold      : hint_range(0.0, 1.0) = 0.55;
uniform float scanline_strength    : hint_range(0.0, 1.0) = 0.04;
uniform float exposure             : hint_range(0.5, 2.0) = 1.05;
uniform float contrast             : hint_range(0.5, 2.0) = 1.12;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 center_offset = uv - vec2(0.5);
    float dist = length(center_offset);

    // Chromatic aberration — radial RGB split, stronger toward edges
    vec2 ca = center_offset * chromatic_aberration * 0.0025 * dist;
    float r = texture(SCREEN_TEXTURE, uv + ca).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv - ca).b;
    vec3 color = vec3(r, g, b);

    // Cheap bloom — sample blurred mip, threshold, accumulate
    vec3 bloom = vec3(0.0);
    float step_size = 0.006;
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            vec2 off = vec2(float(i), float(j)) * step_size;
            vec3 s = textureLod(SCREEN_TEXTURE, uv + off, 2.0).rgb;
            bloom += max(s - vec3(bloom_threshold), vec3(0.0));
        }
    }
    bloom /= 25.0;
    color += bloom * bloom_strength;

    // Exposure + contrast
    color *= exposure;
    color = (color - 0.5) * contrast + 0.5;

    // Vignette
    float vig = smoothstep(vignette_radius, vignette_radius - 0.55, dist);
    color *= mix(1.0 - vignette_strength * 0.7, 1.0, vig);

    // Film grain
    float grain = rand(uv * vec2(1920.0, 1080.0) + vec2(TIME * 37.0, TIME * 13.0)) - 0.5;
    color += vec3(grain) * grain_strength;

    // Subtle scanlines
    float scan = sin(uv.y * 1400.0) * 0.5 + 0.5;
    color *= 1.0 - scanline_strength * (1.0 - scan);

    COLOR = vec4(clamp(color, 0.0, 1.5), 1.0);
}
