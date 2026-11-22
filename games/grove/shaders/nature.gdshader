shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
// 팩이 달라도 같은 느낌이 나도록 모든 숲 모델이 쓰는 재질.
// recolor > 0이면 텍스처 밝기만 남기고 tint 색으로 다시 칠한다(계절 색).

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float recolor : hint_range(0.0, 1.0) = 0.0;
uniform float sway = 0.0;
uniform float alpha_cut : hint_range(0.0, 1.0) = 0.5;
uniform float sun_wrap : hint_range(0.0, 1.0) = 0.35;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0);
	float t = TIME * 1.7 + world.x * 0.55 + world.z * 0.4;
	float gust = sin(t) * 0.7 + sin(t * 2.3 + VERTEX.x) * 0.3;
	VERTEX.x += gust * sway * h * h * 0.01;
	VERTEX.z += cos(t * 0.8) * sway * h * h * 0.006;
}

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	float lum = dot(tex.rgb, vec3(0.3, 0.55, 0.15));
	vec3 painted = tint.rgb * (0.55 + lum * 1.3);
	ALBEDO = mix(tex.rgb * tint.rgb, painted, recolor);
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ROUGHNESS = 0.92;
	SPECULAR = 0.15;
}

void light() {
	// 부드러운 2단계 빛: 그늘이 너무 검지 않게 감싼다
	float ndl = dot(NORMAL, LIGHT);
	float wrap = clamp((ndl + sun_wrap) / (1.0 + sun_wrap), 0.0, 1.0);
	float band = smoothstep(0.18, 0.42, wrap) * 0.7 + wrap * 0.3;
	DIFFUSE_LIGHT += band * ATTENUATION * LIGHT_COLOR / PI;
}
