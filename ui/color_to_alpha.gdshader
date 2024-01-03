shader_type canvas_item;

uniform vec3 alpha_color: source_color;
uniform float threshold: hint_range(-0.1, 1.0, 0.1) = -0.1;

void fragment() {
	bool not_alpha_color = length(COLOR.rgb - alpha_color) > threshold;
	COLOR.a *= float(not_alpha_color);
}
