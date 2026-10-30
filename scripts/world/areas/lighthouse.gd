extends Node3D
## LOCATION E — THE LIGHTHOUSE (surface tower).
## Octagonal tower with walkable interior: ground floor (sealed hatch, barred
## front door, the grate you came up through), maintenance landing (+6 m),
## control room (+12 m, seal release). The beacon above has a rule of its own:
## it stops turning while you look straight at it.

const C := Vector3(0, 16.5, -82)
const R_IN := 5.6
const S := 3.1      # half-size of the stair square (landings must fit inside the octagon)
const TOP := 15.5

var level: Node
var beacon: Node3D
var beam_light: SpotLight3D
var _beam_mesh: MeshInstance3D
var _beacon_speed := 0.55
var _flare := 0.0
var hatch: Node3D
var _hatch_open := false
var _release_heard := false
var _stopped_note := false


func build(lv: Node) -> void:
	level = lv
	add_to_group("navsrc_surface")
	add_to_group("beacon")
	level.checkpoints["lighthouse"] = [C + Vector3(-1.5, 0.2, 2.0), 0.0, "surface"]
	level.checkpoints["aftermath"] = [C + Vector3(1.5, 0.2, 2.5), 180.0, "surface"]
	_tower()
	_stairs_and_floors()
	_ground_floor()
	_landing()
	_control_room()
	_beacon()
	Zone.make(self, C + Vector3(0, 7.5, 0), Vector3(9.6, 15, 9.6), {"ambience": "lighthouse", "reverb": 0.3})
	Zone.make(self, C + Vector3(0, 2, 18), Vector3(30, 10, 22), {"ambience": "settlement"})
	Zone.make(self, C + Vector3(0, 1.5, 8.5), Vector3(6, 3, 3), {"once": true, "require": "chose_break", "on_enter": func(_b):
		await get_tree().create_timer(2.0).timeout
		Sound.say("[your footsteps — exactly when you take them]", "aside", 4.0)})
	Zone.make(self, C + Vector3(0, 1.5, 8.5), Vector3(6, 3, 3), {"once": true, "require": "chose_send", "on_enter": func(_b):
		await get_tree().create_timer(2.0).timeout
		Sound.pre_echo("radio_voice_elias", C + Vector3(0, TOP, 0), "[the beacon is broadcasting your voice — words you haven't said]", 0.0)})


func _tower() -> void:
	var plaster := B.mat("plaster_white", Color(0.85, 0.85, 0.82), 0.35)
	var inner := B.mat("plaster_white", Color(0.55, 0.56, 0.54), 0.45)
	var red := B.mat("metal_red", Color(0.8, 0.7, 0.7), 0.4)
	var side := 2.0 * R_IN * tan(PI / 8.0) + 0.05
	for i in 8:
		var a := PI / 8.0 + i * PI / 4.0 - PI / 8.0   # face normals at 0,45,90.. degrees
		var n := Vector3(sin(a), 0, cos(a))
		var center := C + n * (R_IN + 0.2)
		var is_door := i == 0   # face pointing +z (south) holds the front door
		var segments := []
		if is_door:
			segments = [[0.0, 0.0, 2.3, -1.0, 1.4 - 0.55], [0.0, 0.0, 2.3, 1.0, 1.4 - 0.55], [2.3, 0.0, TOP - 2.3, 0.0, side]]
			# [y0, unused, height, offset, width]
		else:
			segments = [[0.0, 0.0, TOP, 0.0, side]]
		for s in segments:
			var w: float = s[4]
			var h: float = s[2]
			var off: float = s[3] * (side * 0.5 - w * 0.5)
			var tangent := Vector3(cos(a), 0, -sin(a))
			var p: Vector3 = center + tangent * off + Vector3(0, s[0] + h * 0.5, 0)
			var wall := B.box(self, p, Vector3(w, h, 0.4), inner, {"surface": "stone"})
			wall.rotation.y = a


	# the exterior is the Blender model (tools/blender/build_models.py)
	Models.spawn("res://assets/models/lighthouse.glb", self, C, 0.0, ["LighthouseShell"])
	# short tunnel through the thick wall to the door
	for sx in [-1, 1]:
		B.box(self, C + Vector3(sx * 0.75, 1.3, R_IN + 0.95), Vector3(0.3, 2.6, 1.5), B.mat("stone_blocks", Color.WHITE, 0.35), {"surface": "stone"})
	B.box(self, C + Vector3(0, 2.75, R_IN + 0.95), Vector3(1.8, 0.3, 1.5), B.mat("stone_blocks", Color.WHITE, 0.35), {})
	# front door (barred from the inside)
	var door := Door.make(self, C + Vector3(0, 0, R_IN + 0.2), 0, {"id": "lh_front", "w": 1.2, "h": 2.3, "lock": "lh_unbarred",
		"locked_text": "Barred from the inside.", "mat": B.mat("wood_dark", Color(0.6, 0.5, 0.45), 0.6)})
	var bar := B.box(self, C + Vector3(0, 1.2, R_IN - 0.05), Vector3(1.6, 0.14, 0.14), B.mat("wood_dark", Color.WHITE, 1.0), {"collide": false})
	var unbar := Interactable.make(self, C + Vector3(0, 1.2, R_IN - 0.3), Vector3(1.6, 0.5, 0.4), "Lift the bar from the door")
	unbar.once = true
	unbar.used.connect(func(p):
		Game.set_flag("lh_unbarred")
		bar.queue_free()
		Sound.play_at("door_slam", bar.global_position, -8.0)
		p.hud.toast("The bar lifts away."))
	if Game.has_flag("lh_unbarred"):
		bar.queue_free()
		unbar.queue_free()
	# outer apron
	B.cyl(self, C + Vector3(0, -0.3, 0), R_IN + 3.0, 0.6, B.mat("stone_wet", Color.WHITE, 0.4), {"segments": 16, "surface": "stone"})


func _stairs_and_floors() -> void:
	var wood := B.mat("wood_planks", Color(0.75, 0.72, 0.66), 0.6)
	var iron := B.mat("metal_rust", Color(0.7, 0.7, 0.7), 1.0, {"metallic": 0.4})
	var s := S
	var w := 1.1
	var e := s + w * 0.5
	# F1 north 0->3, F2 east 3->6, F3 south 6->9, F4 west 9->12
	B.stairs(self, C + Vector3(-s + 0.3, 0, -e), C + Vector3(s, 3.0, -e), w, iron, "metal")
	B.box(self, C + Vector3(e, 2.9, -e), Vector3(w + 0.1, 0.2, w + 0.1), iron, {"surface": "metal"})
	B.stairs(self, C + Vector3(e, 3.0, -s), C + Vector3(e, 6.0, s), w, iron, "metal")
	B.stairs(self, C + Vector3(s, 6.0, e), C + Vector3(-s, 9.0, e), w, iron, "metal")
	B.box(self, C + Vector3(-e, 8.9, e), Vector3(w + 0.1, 0.2, w + 0.1), iron, {"surface": "metal"})
	B.stairs(self, C + Vector3(-e, 9.0, s), C + Vector3(-e, 12.0, -s), w, iron, "metal")
	# floors: ground; landing at 6 (east strip open over F2); control room at 12 (west strip open over F4)
	var r := R_IN
	B.cyl(self, C + Vector3(0, -0.1, 0), r + 0.1, 0.2, wood, {"segments": 8, "surface": "wood"})
	B.box(self, C + Vector3((s - r) * 0.5, 5.9, 0), Vector3(s + r, 0.2, r * 2.0), wood, {"surface": "wood"})
	B.box(self, C + Vector3(e, 5.9, e), Vector3(w + 0.1, 0.2, w + 0.1), wood, {"surface": "wood"})
	B.box(self, C + Vector3((r - s) * 0.5, 11.9, 0), Vector3(s + r, 0.2, r * 2.0), wood, {"surface": "wood"})
	B.box(self, C + Vector3(-e, 11.9, -e), Vector3(w + 0.1, 0.2, w + 0.1), wood, {"surface": "wood"})
	B.box(self, C + Vector3(0, TOP - 0.1, 0), Vector3(r * 2.0, 0.2, r * 2.0), B.mat("wood_dark", Color.WHITE, 0.6), {"collide": true})
	# railings so nobody steps off a landing into the stairwell (each leaves its landing corner open)
	B.collider(self, C + Vector3(s - 0.05, 7.0, (s - r) * 0.5), Vector3(0.1, 2.0, r + s))
	B.box(self, C + Vector3(s - 0.05, 7.0, (s - r) * 0.5), Vector3(0.06, 0.06, r + s), iron, {"collide": false})
	B.collider(self, C + Vector3(-s + 0.05, 13.0, (r - s) * 0.5), Vector3(0.1, 2.0, r + s))
	B.box(self, C + Vector3(-s + 0.05, 13.0, (r - s) * 0.5), Vector3(0.06, 0.06, r + s), iron, {"collide": false})
	# lamps
	for y in [2.6, 8.6, 14.6]:
		var l := B.omni(self, C + Vector3(0, y, 0), Color(1.0, 0.72, 0.42), 0.9, 8.0, y < 3.0)
		l.set_script(preload("res://scripts/world/flicker.gd"))
		B.sphere(self, C + Vector3(0, y + 0.1, 0), 0.12, B.glow(Color(1.0, 0.72, 0.42), 3.0))


func _ground_floor() -> void:
	# the grate you came up through, and the sealed hatch to the lower level
	var iron := B.mat("metal_rust", Color(0.6, 0.6, 0.6), 1.0, {"metallic": 0.5})
	B.box(self, C + Vector3(-2.2, 0.02, 2.4), Vector3(1.2, 0.04, 1.2), iron, {"collide": false})
	var down := Interactable.make(self, C + Vector3(-2.2, 0.3, 2.4), Vector3(1.2, 0.6, 1.2), "Climb down the grate to the caves")
	down.used.connect(func(_p):
		level.travel(level.areas["caves"].stair_spawn(), 0.0, "caves", "caves"))
	hatch = Node3D.new()
	add_child(hatch)
	hatch.position = C + Vector3(0.3, 0.02, 0.2)
	var lid := B.cyl(hatch, Vector3(0, 0.05, 0), 0.75, 0.1, iron, {"collide": false, "segments": 16})
	B.cyl(hatch, Vector3(0, 0.15, 0), 0.3, 0.05, B.flat(Color(0.4, 0.08, 0.06), 0.5, 0.6), {"collide": false})
	var hatch_it := Interactable.make(self, C + Vector3(0.3, 0.3, 0.2), Vector3(1.6, 0.6, 1.6), "Sealed hatch")
	hatch_it.used.connect(_on_hatch)
	P.crate(self, C + Vector3(3.0, 0, 1.6), 20)
	P.barrel(self, C + Vector3(2.6, 0, 2.8))
	P.shelf(self, C + Vector3(-3.2, 0, 0.6), 90, 1.2)
	P.note(self, C + Vector3(2.6, 0.82, 1.2), "keeper_log", 0)
	Zone.make(self, C + Vector3(0, 1.5, 0), Vector3(6, 3, 6), {"once": true, "block": "lh_line", "on_enter": func(_b):
		Game.set_flag("lh_line")
		level.chapter("ch_lighthouse")
		level.hud.elias("lighthouse", 2.0)})
	# on the stairs: The Listener, on the landing above, for a moment
	Zone.make(self, C + Vector3(S + 0.55, 4.5, 0), Vector3(1.4, 3, 4), {"once": true, "block": "lh_glimpse", "on_enter": func(_b):
		Game.set_flag("lh_glimpse")
		level.horror.listener_glimpse(C + Vector3(-1.5, 6.0, 2.5), PI * 0.75, null, 1.2)})
	if Game.has_flag("seal_released"):
		_set_hatch_open(true)


func _on_hatch(p: Node) -> void:
	if not Game.has_flag("seal_released"):
		p.hud.toast("Sealed. A wheel lock, engaged from somewhere above.")
		return
	if not Game.has_flag("reached_chamber"):
		Game.set_flag("reached_chamber")
		level.objective("arm_transmitter")
		Game.state.checkpoint = "chamber"
		level.checkpoint("chamber")
	var cp: Array = level.checkpoints["chamber"]
	await level.travel(cp[0], cp[1], "chamber", "chamber")
	level.areas["chamber"].enter()


func _set_hatch_open(on: bool) -> void:
	_hatch_open = on
	hatch.rotation_degrees.x = -100.0 if on else 0.0
	hatch.position = C + (Vector3(0.3, 0.02, -0.55) if on else Vector3(0.3, 0.02, 0.2))
	var it: Interactable = null
	for c in get_children():
		if c is Interactable and c.prompt == "Sealed hatch":
			it = c
	if it and on:
		it.prompt = "Descend to the lower level"


func _landing() -> void:
	var y := 6.0
	P.table(self, C + Vector3(-1.5, y, -2.0), 30, Vector2(1.2, 0.7))
	P.chair(self, C + Vector3(-0.8, y, -1.2), 200)
	P.note(self, C + Vector3(-1.5, y + 0.8, -2.0), "landing_note", 20)
	P.crate(self, C + Vector3(-3.0, y, 2.6), 0)
	var deck := Node3D.new()
	add_child(deck)
	deck.position = C + Vector3(-1.2, y + 0.8, -2.25)
	B.box(deck, Vector3(0.45, 0.1, 0), Vector3(0.4, 0.2, 0.3), B.mat("metal_green", Color.WHITE, 2.0), {"collide": false})
	var it := Interactable.make(self, deck.global_position + Vector3(0.45, 0.1, 0), Vector3(0.5, 0.4, 0.5), "Play the tape")
	it.used.connect(func(p):
		Sound.play_at("tape_start", it.global_position, -6.0)
		Sound.play_at("radio_voice_elias", it.global_position, -4.0, {"bus": "Voice"})
		p.hud.radio("landing_voice"))


func _control_room() -> void:
	var y := 12.0
	var metal := B.mat("metal_green", Color(0.7, 0.75, 0.7), 1.2, {"metallic": 0.4})
	B.box(self, C + Vector3(2.2, y + 0.5, -2.6), Vector3(2.6, 1.0, 0.8), metal, {"surface": "metal"})
	B.box(self, C + Vector3(2.2, y + 1.3, -2.95), Vector3(2.6, 0.7, 0.15), metal, {"collide": false})
	for i in 4:
		B.cyl(self, C + Vector3(1.3 + i * 0.6, y + 1.35, -2.86), 0.12, 0.03, B.glow(Color(0.9, 0.6, 0.3), 0.6), {"collide": false, "rot": Vector3(90, 0, 0)})
	var lever := Node3D.new()
	add_child(lever)
	lever.position = C + Vector3(3.2, y + 1.0, -2.4)
	B.box(lever, Vector3(0, 0.25, 0), Vector3(0.06, 0.5, 0.06), B.flat(Color(0.3, 0.3, 0.3), 0.4, 0.8), {"collide": false})
	B.sphere(lever, Vector3(0, 0.52, 0), 0.06, B.flat(Color(0.6, 0.08, 0.05), 0.4))
	lever.rotation_degrees.x = -30
	P.note(self, C + Vector3(2.6, y + 1.02, -2.3), "control_note", 0)
	var it := Interactable.make(self, lever.global_position + Vector3(0, 0.3, 0), Vector3(0.5, 0.7, 0.5), "Pull the seal release")
	it.used.connect(func(p):
		if Game.has_flag("seal_released"):
			p.hud.toast("The release is down.")
			return
		Game.set_flag("seal_released")
		var tw := create_tween()
		tw.tween_property(lever, "rotation_degrees:x", 40.0, 0.4)
		# The sound already happened. Pulling it now is silent.
		Sound.play_at("rec_button", lever.global_position, -12.0)
		_set_hatch_open(true)
		await get_tree().create_timer(1.2).timeout
		Sound.say("[silence. You already heard it open.]", "aside", 3.5)
		level.objective("descend")
		level.checkpoint("lighthouse"))
	if Game.has_flag("seal_released"):
		lever.rotation_degrees.x = 40
	# Pre-echo: the hatch grinds open below as you approach the lever.
	Zone.make(self, C + Vector3(2.5, y + 1.0, -1.5), Vector3(3.5, 2.0, 3.0), {"once": true, "block": "seal_released", "on_enter": func(_b):
		Sound.pre_echo("hatch_open", C + Vector3(0.3, 0.5, 0.2), "[far below, the hatch grinds open — you haven't touched the release]", 4.0)})
	# the tape that contradicts the one on the landing
	var tape := Interactable.make(self, C + Vector3(1.2, y + 1.1, -2.6), Vector3(0.5, 0.4, 0.5), "Play the tape")
	B.box(self, C + Vector3(1.2, y + 1.05, -2.6), Vector3(0.4, 0.2, 0.3), B.mat("metal_green", Color.WHITE, 2.0), {"collide": false})
	tape.used.connect(func(p):
		Sound.play_at("tape_start", tape.global_position, -6.0)
		Sound.play_at("radio_voice_elias", tape.global_position, -4.0, {"bus": "Voice"})
		p.hud.radio("control_voice"))
	for wy in [0.0]:
		var win := B.box(self, C + Vector3(0, y + 1.6, R_IN + 0.02), Vector3(1.6, 1.0, 0.03), B.glass(), {"collide": false})


func _beacon() -> void:
	beacon = Node3D.new()
	add_child(beacon)
	beacon.position = C + Vector3(0, TOP + 3.1, 0)
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	core.mesh = sm
	var cm := B.glow(Color(1.0, 0.85, 0.55), 8.0, true).duplicate() as StandardMaterial3D
	cm.disable_fog = true
	core.material_override = cm
	beacon.add_child(core)
	beam_light = SpotLight3D.new()
	beam_light.light_color = Color(1.0, 0.88, 0.65)
	beam_light.light_energy = 14.0
	beam_light.spot_range = 160.0
	beam_light.spot_angle = 6.0
	beam_light.spot_attenuation = 0.6
	beam_light.light_volumetric_fog_energy = 4.0
	beacon.add_child(beam_light)
	beam_light.rotation_degrees.x = -4.0
	_beam_mesh = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 9.0
	cyl.height = 140.0
	cyl.radial_segments = 16
	_beam_mesh.mesh = cyl
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.albedo_color = Color(1.0, 0.85, 0.6, 0.035)
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.disable_fog = true
	_beam_mesh.material_override = bm
	_beam_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.add_child(_beam_mesh)
	_beam_mesh.rotation_degrees.x = -90 - 4.0
	_beam_mesh.position = Vector3(0, -70.0 * sin(deg_to_rad(4.0)), -70.0)
	# the beacon hum carries over the island
	Sound.attach_loop(beacon, "amb_signal", -4.0, {"unit_size": 30.0, "max_distance": 260.0})


func flare() -> void:
	_flare = 1.0


func _process(delta: float) -> void:
	if beacon == null or level.player == null:
		return
	var cam: Camera3D = level.player.camera
	var to: Vector3 = beacon.global_position - cam.global_position
	var looking: bool = level.space == "surface" and to.length() > 25.0 and (-cam.global_transform.basis.z).dot(to.normalized()) > 0.992
	var speed := 0.0 if looking else _beacon_speed * (2.0 if Game.has_flag("chose_send") else 1.0)
	if Game.has_flag("chose_break"):
		speed = 0.0
	beacon.rotation.y += delta * speed
	if looking and not _stopped_note and Game.has_flag("entered_settlement"):
		_stopped_note = true
		Sound.say("[the beacon has stopped turning. It's facing you.]", "aside", 3.5)
	_flare = max(_flare - delta * 0.15, 0.0)
	var e := 14.0 + _flare * 40.0 + (14.0 if Game.has_flag("chose_send") else 0.0)
	if Game.has_flag("chose_break"):
		e = 0.0
	beam_light.light_energy = e
	_beam_mesh.visible = e > 0.0
	(_beam_mesh.material_override as StandardMaterial3D).albedo_color.a = 0.035 + _flare * 0.08 + (0.03 if Game.has_flag("chose_send") else 0.0)
