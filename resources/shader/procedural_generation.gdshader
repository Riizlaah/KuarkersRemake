shader_type spatial;

uniform sampler2D trn_color;

uniform float min_height = 0;
uniform float max_height = 1;

varying float vertex_y;

float inverse_lerp(float a, float b, float val) {
	float value = (val - a) / (b - a);
	return clamp(0.01, 1.0, value);
}

void fragment() {
	float height = vertex_y;
	float position = inverse_lerp(min_height, max_height, height);
	vec3 color = texture(trn_color, vec2(position, 0)).rgb;
	ALBEDO = color;
}

void vertex() {
	vertex_y = VERTEX.y;
}

