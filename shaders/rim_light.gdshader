shader_type canvas_item;

// Rim-light / metallic tint shader for Polygon2D entities.
// Gives procedural shapes a sense of volume and material until real sprites arrive.

uniform vec4 base_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.65, 0.35, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 2.5;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.9;
uniform float emission_strength : hint_range(0.0, 3.0) = 0.4;
uniform float pulse_speed : hint_range(0.0, 8.0) = 2.2;

void fragment() {
    vec4 tex = COLOR;
    // Fake rim based on alpha gradient near polygon edges
    float edge = 1.0 - smoothstep(0.0, 0.5, tex.a);
    float rim = pow(edge, rim_power) * rim_strength;
    float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);

    vec3 body = tex.rgb * base_tint.rgb;
    vec3 final_color = body + rim_color.rgb * rim * pulse + body * emission_strength * 0.5;
    COLOR = vec4(final_color, tex.a);
}
