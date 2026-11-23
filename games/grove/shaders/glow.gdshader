shader_type spatial;
render_mode unshaded, blend_add, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;
// 붙일 수 있는 자리의 노을빛 원. 늘 카메라를 보고, 나무에 가려도 보이며, 숨 쉬듯 빛난다.

uniform vec4 color : source_color = vec4(0.95, 0.62, 0.3, 1.0);
uniform float strength = 1.0;

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float ring = smoothstep(1.0, 0.82, d) * smoothstep(0.5, 0.78, d);
	float core = pow(max(1.0 - d, 0.0), 2.0) * 0.45;
	float breathe = 0.7 + 0.3 * sin(TIME * 3.2);
	ALBEDO = color.rgb * (ring + core) * strength * breathe;
}
