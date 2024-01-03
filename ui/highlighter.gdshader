shader_type canvas_item;

uniform float additional_brightness: hint_range(0.0, 1.0, 0.01) = 0.;

void fragment() {
	COLOR += additional_brightness * COLOR.a;
}
