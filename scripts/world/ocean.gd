class_name Ocean
extends MeshInstance3D
## Black, slow sea. Its height is the tide: the station transmission pulls it
## out, Ending A lets it return.

const HIGH := 0.0
const LOW := -2.6

var level := HIGH


func build() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(1400, 1400)
	pm.subdivide_width = 140
	pm.subdivide_depth = 140
	mesh = pm
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, specular_schlick_ggx;
uniform vec4 deep : source_color = vec4(0.015, 0.03, 0.038, 1.0);
uniform vec4 crest : source_color = vec4(0.07, 0.1, 0.11, 1.0);
uniform sampler2D ripple : hint_normal, filter_linear_mipmap, repeat_enable;
varying float hgt;
float wave(vec2 p, vec2 dir, float freq, float speed, float amp) {
	return sin(dot(p, normalize(dir)) * freq + TIME * speed) * amp;
}
void vertex() {
	vec2 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	float h = wave(p, vec2(1.0, 0.3), 0.08, 0.7, 0.35) + wave(p, vec2(-0.4, 1.0), 0.13, 1.1, 0.2) + wave(p, vec2(0.7, -0.8), 0.31, 1.7, 0.07);
	VERTEX.y += h;
	hgt = h;
	float e = 0.5;
	float hx = wave(p + vec2(e, 0.0), vec2(1.0, 0.3), 0.08, 0.7, 0.35) + wave(p + vec2(e, 0.0), vec2(-0.4, 1.0), 0.13, 1.1, 0.2);
	float hz = wave(p + vec2(0.0, e), vec2(1.0, 0.3), 0.08, 0.7, 0.35) + wave(p + vec2(0.0, e), vec2(-0.4, 1.0), 0.13, 1.1, 0.2);
	NORMAL = normalize(vec3(h - hx, e, h - hz));
}
void fragment() {
	vec2 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec3 n1 = texture(ripple, wp * 0.05 + TIME * vec2(0.01, 0.006)).rgb;
	vec3 n2 = texture(ripple, wp * 0.11 - TIME * vec2(0.008, 0.012)).rgb;
	NORMAL_MAP = normalize(n1 + n2 - 1.0) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 0.6;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mix(deep.rgb, crest.rgb, clamp(hgt * 1.5 + 0.4, 0.0, 1.0)) + fres * vec3(0.05, 0.07, 0.08);
	ROUGHNESS = 0.08;
	METALLIC = 0.1;
	SPECULAR = 0.7;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	var nt := NoiseTexture2D.new()
	nt.seamless = true
	nt.as_normal_map = true
	nt.bump_strength = 6.0
	nt.width = 256
	nt.height = 256
	var fn := FastNoiseLite.new()
	fn.frequency = 0.03
	nt.noise = fn
	m.set_shader_parameter("ripple", nt)
	material_override = m
	position.y = level


func set_level(y: float, time := 0.0) -> void:
	level = y
	if time <= 0.0:
		position.y = y
	else:
		var tw := create_tween()
		tw.tween_property(self, "position:y", y, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	get_tree().call_group("tide_watchers", "on_tide", y, time)
