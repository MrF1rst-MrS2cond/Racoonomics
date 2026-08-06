shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float line_width = 1.0;
uniform vec2 grid_size = vec2(10.0, 10.0);
uniform vec3 world_offset;

varying vec3 v_world_pos;

void vertex() {
	// Берем честные координаты вершин меша в 3D пространстве
	vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	v_world_pos = world_pos.xyz - world_offset;
}

void fragment() {
	// Используем позиции вершин для генерации сетки
	vec2 grid_uv = v_world_pos.xz / grid_size;
	vec2 uv_deriv = fwidth(grid_uv);
	vec2 grid_dist = abs(fract(grid_uv + 0.5) - 0.5);

	vec2 line_aa = uv_deriv * 0.5;
	vec2 line_alphas = 1.0 - smoothstep(uv_deriv * line_width * 0.5 - line_aa, uv_deriv * line_width * 0.5 + line_aa, grid_dist);
	float on_line = max(line_alphas.x, line_alphas.y);

	ALBEDO = line_color.rgb;
	ALPHA = line_color.a * on_line;
}