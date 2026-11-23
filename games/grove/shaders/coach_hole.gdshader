shader_type canvas_item;
// 처음 안내(Coach): 화면을 어둡게 덮고 봐야 할 곳만 둥근 구멍으로 비운다. 구멍 둘레가 노을빛으로 숨 쉰다.

uniform vec4 hole = vec4(0.0);
uniform vec2 area = vec2(1920.0, 1080.0);
uniform float radius = 28.0;
uniform vec4 dim : source_color = vec4(0.07, 0.12, 0.09, 0.6);
uniform vec4 edge : source_color = vec4(0.95, 0.62, 0.3, 1.0);

void fragment() {
	vec2 p = UV * area;
	vec2 c = hole.xy + hole.zw * 0.5;
	vec2 q = abs(p - c) - hole.zw * 0.5 + radius;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	float outside = hole.z > 0.0 ? smoothstep(0.0, 8.0, d) : 1.0;
	float ring = hole.z > 0.0 ? (1.0 - smoothstep(0.0, 5.0, abs(d - 6.0))) * (0.65 + 0.35 * sin(TIME * 3.2)) : 0.0;
	COLOR = mix(vec4(dim.rgb, dim.a * outside), vec4(edge.rgb, 1.0), ring);
}
