shader_type sky;

uniform vec3 skyColor: source_color;
uniform vec3 horizonColor: source_color;

void sky() {
	float col = clamp(EYEDIR.y / 0.05, 0.0, 1.0);
	vec3 final_color = mix(horizonColor, skyColor, col);
	COLOR = final_color * LIGHT0_ENERGY;
}