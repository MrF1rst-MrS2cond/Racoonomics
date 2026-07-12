shader_type spatial;
render_mode unshaded, cull_disabled;

uniform bool is_valid;
uniform bool is_warning;

uniform float fresnel_power = 3.0;
uniform float fresnel_sharpness : hint_range(0.0, 1.0) = 0.5;

uniform float scanline_scale;
uniform float scanline_speed;

uniform vec4 wire_color_valid : source_color;
uniform vec4 fill_color_valid : source_color;

uniform vec4 wire_color_invalid : source_color;
uniform vec4 fill_color_invalid : source_color;

uniform vec4 warning_color : source_color;

void vertex() {
	UV = VERTEX.xy;
	VERTEX += NORMAL * (is_valid ? 0.0 : 0.0001);
}

void fragment() {
	float fresnel = 1.0 - dot(NORMAL, VIEW);
	fresnel = pow(fresnel, fresnel_power);
	float edge = smoothstep(0.5 - fresnel_sharpness * 0.5, 0.5 + fresnel_sharpness * 0.5, fresnel);

	vec4 edge_color = is_valid ? wire_color_valid : wire_color_invalid;
	vec4 fill_color = is_valid ? fill_color_valid : fill_color_invalid;

	float ff_mult = FRONT_FACING ? 1.0 : 0.3;
	vec4 warning_mult = is_warning ? warning_color : vec4(1.0);
	float scanline = fract((UV.x + UV.y) * scanline_scale + TIME * scanline_speed) < 0.7 ? 1.0 : 0.3;
	vec4 final_color = mix(fill_color, edge_color, edge) * scanline;

	ALBEDO = final_color.rgb * ff_mult * warning_mult.rgb;
	ALPHA = final_color.a * ff_mult * warning_mult.a;
}