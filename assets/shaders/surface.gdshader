// Shared surface for every textured material on the island (B.mat).
// Triplanar PBR like before, plus what years of sea weather do to a place:
// large patchy grime so tiling never repeats, moss gathering on surfaces that
// face the sky, and wet patches that darken and turn glossy.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D tex_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_rough : hint_roughness_r, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_macro : filter_linear_mipmap, repeat_enable;
uniform sampler2D tex_moss : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float uv_scale = 0.35;
uniform float normal_scale = 1.0;
uniform float roughness = 1.0;
uniform float metallic = 0.0;
uniform float grime = 0.5;
uniform float moss = 0.0;
uniform float wet = 0.0;

varying vec3 tp_pos;
varying vec3 tp_w;
varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	TANGENT = normalize(vec3(0.0, 0.0, -1.0) * abs(NORMAL.x) + vec3(1.0, 0.0, 0.0) * abs(NORMAL.y) + vec3(1.0, 0.0, 0.0) * abs(NORMAL.z));
	BINORMAL = normalize(vec3(0.0, 1.0, 0.0) * abs(NORMAL.x) + vec3(0.0, 0.0, -1.0) * abs(NORMAL.y) + vec3(0.0, 1.0, 0.0) * abs(NORMAL.z));
	tp_w = pow(abs(w_nrm), vec3(4.0));
	tp_w /= dot(tp_w, vec3(1.0));
	tp_pos = w_pos * uv_scale * vec3(1.0, -1.0, 1.0);
}

vec4 tri(sampler2D s, vec3 p, vec3 w) {
	return texture(s, p.xy) * w.z + texture(s, p.xz) * w.y + texture(s, p.zy * vec2(-1.0, 1.0)) * w.x;
}

void fragment() {
	vec3 alb = tri(tex_albedo, tp_pos, tp_w).rgb * tint.rgb;
	float rough = tri(tex_rough, tp_pos, tp_w).r * roughness;
	vec3 mac = texture(tex_macro, w_pos.xz * 0.035 + w_pos.y * 0.011).rgb;
	vec3 mac2 = texture(tex_macro, w_pos.zy * 0.09 + w_pos.x * 0.02).rgb;
	// patchy grime: some boards and stones darker, some bleached
	alb *= mix(1.0, 0.68 + 0.6 * mac.r * (0.75 + 0.5 * mac2.b), grime);
	// moss where the sky reaches and the patch noise agrees
	float up = clamp(w_nrm.y, 0.0, 1.0);
	float m = moss * smoothstep(0.55, 0.85, up * 0.55 + mac.g * 0.55 + mac.b * 0.15);
	m = max(m, moss * 0.6 * smoothstep(0.78, 0.95, mac2.g) * (1.0 - up));   // a little climbs the walls
	vec3 mc = tri(tex_moss, tp_pos * 1.3, tp_w).rgb;
	alb = mix(alb, mc, m);
	// wet patches: darker and glossier, more of them low down
	float wm = wet * smoothstep(0.62, 0.35, mac2.g + clamp(w_pos.y * 0.004, 0.0, 0.2));
	alb *= 1.0 - 0.38 * wm;
	rough = mix(rough, 0.28, wm * (1.0 - m));
	ALBEDO = alb;
	ROUGHNESS = clamp(mix(rough, 0.95, m), 0.05, 1.0);
	METALLIC = metallic * (1.0 - m);
	NORMAL_MAP = tri(tex_normal, tp_pos, tp_w).rgb;
	NORMAL_MAP_DEPTH = normal_scale * (1.0 - 0.4 * m) * (1.0 - 0.6 * wm);   // water fills the cracks
}
