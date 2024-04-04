shader_type spatial;

uniform sampler2D grass;
uniform sampler2D low_grass;
uniform float min_height = -0.30;
uniform float max_height = 1.6;
varying float vertex_y;
uniform vec2 uvscale = vec2(5);

void fragment() {
	float vert_height = vertex_y;
	vec3 grass2 = texture(grass, UV * uvscale).rgb;
	vec3 low_grass2 = texture(low_grass, UV * uvscale).rgb;
	float weight = smoothstep(min_height, max_height, vert_height);
	vec3 final = mix(low_grass2, grass2, weight);
	ALBEDO = final;
}

void vertex() {
	vertex_y = VERTEX.y;
}