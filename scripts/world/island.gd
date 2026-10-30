extends Node3D
## Level root. Builds Vey Isle from code, spawns the player at the current
## checkpoint, owns The Listener, the navigation regions and the travel
## transitions between the surface and the spaces beneath it.

const CAVE_ORIGIN := Vector3(0, -200, 0)
const CHAMBER_ORIGIN := Vector3(0, -200, -260)
const ROOST_ORIGIN := Vector3(0, -200, 220)
const ANNEX_ORIGIN := Vector3(220, -200, 0)

## flag that unlocks each journal entry
const JOURNAL_FLAGS := {
	"left_boat": "j_arrival", "dock_echo": "j_preecho", "has_station_key": "j_key", "reached_station": "j_station",
	"tide_out": "j_tide", "lowvey_silence": "j_lowvey", "annex_list": "j_morrow", "read_kell": "j_kell",
	"graveyard_radio": "j_pelagic", "reached_chamber": "j_truth", "armed": "j_choice", "listener_seen": "j_listener",
	"read_wren_customs": "j_curse", "read_wren_1923": "j_curse",
}

## Checkpoint id -> [position, yaw degrees, space]
var checkpoints := {}

var player: Player
var hud: Node
var listener: Node3D
var terrain: Terrain
var ocean: Ocean
var env: Environment
var moon: DirectionalLight3D
var world_env: WorldEnvironment
var pause_menu: Node
var areas := {}
var nav_regions := {}
var space := "surface"
var horror: Node3D
var _last_hour := -1
var _rain: GPUParticles3D
var _rain_snd: AudioStreamPlayer
var _thunder_t := 20.0


func _ready() -> void:
	Sound.stop_all()
	_build_environment()
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.build()
	terrain.add_to_group("navsrc_surface")
	ocean = Ocean.new()
	ocean.name = "Ocean"
	add_child(ocean)
	ocean.build()
	ocean.set_level(Ocean.LOW if Game.has_flag("tide_out") and not Game.has_flag("tide_returned") else Ocean.HIGH)

	player = Player.new()
	player.name = "Player"
	add_child(player)
	hud = preload("res://scripts/ui/hud.gd").new()
	hud.name = "HUD"
	add_child(hud)
	hud.player = player
	player.hud = hud

	listener = preload("res://scripts/enemy/listener.gd").new()
	listener.name = "Listener"
	add_child(listener)
	listener.level = self

	horror = preload("res://scripts/world/horror.gd").new()
	horror.name = "Horror"
	add_child(horror)
	horror.setup(self)
	for area_name in ["dock", "settlement", "station", "caves", "lighthouse", "chamber", "forest", "graveyard", "lowvey", "annex"]:
		var t0 := Time.get_ticks_msec()
		var a: Node3D = load("res://scripts/world/areas/%s.gd" % area_name).new()
		a.name = area_name.capitalize()
		add_child(a)
		areas[area_name] = a
		a.build(self)
		if Game.debug_ai:
			print("[debug] built %s in %d ms" % [area_name, Time.get_ticks_msec() - t0])

	var imm := preload("res://scripts/world/immersion.gd").new()
	imm.name = "Immersion"
	add_child(imm)
	imm.setup(self)
	_bake_navigation()
	pause_menu = preload("res://scripts/ui/pause_menu.gd").new()
	add_child(pause_menu)
	pause_menu.level = self

	var cp: Array = checkpoints.get(Game.state.checkpoint, checkpoints["dock_start"])
	player.place(cp[0], cp[1])
	set_space(cp[2] if cp.size() > 2 else "surface")
	for a in areas.values():
		if a.has_method("on_spawn"):
			a.on_spawn(Game.state.checkpoint)
	_build_weather()
	Game.flag_set.connect(_on_flag)
	Game.recordings_changed.connect(func():
		if Game.has_recording("dock_steps"):
			Game.add_journal("j_replay")
		if Game.last_recording_complete():
			Game.add_journal("j_last"))
	_last_hour = Game.clock_seconds() / 3600
	if Game.state.checkpoint == "dock_start" and not Game.has_flag("intro_seen"):
		Game.set_flag("intro_seen")
		hud.intro()
	if Game.debug_ai:
		print("[debug] checkpoint ", Game.state.checkpoint, " flags ", Game.state.flags.keys())


func _on_flag(f: String) -> void:
	if JOURNAL_FLAGS.has(f):
		Game.add_journal(JOURNAL_FLAGS[f])


func chapter(flag: String) -> void:
	if Game.has_flag(flag):
		return
	Game.set_flag(flag)
	for c in Story.CHAPTERS:
		if c[0] == flag:
			hud.chapter(c[1], c[2], c[3])


func _process(delta: float) -> void:
	# the island clock; the square's bell strikes every hour (and is heard a little early)
	Game.state.clock = float(Game.state.get("clock", 0.0)) + delta * Game.CLOCK_SPEED
	var hour := Game.clock_seconds() / 3600
	if hour != _last_hour:
		_last_hour = hour
		get_tree().call_group("hourly", "on_hour", hour)
	if _rain:
		_rain.global_position = player.global_position + Vector3(0, 9, 0)
		_rain.emitting = space == "surface"
		_rain_snd.volume_db = lerp(_rain_snd.volume_db, -24.0 if space == "surface" else -80.0, delta * 2.0)
		_thunder_t -= delta
		if _thunder_t <= 0.0 and space == "surface":
			_thunder_t = randf_range(110.0, 200.0)
			_lightning()


func _build_weather() -> void:
	_rain = GPUParticles3D.new()
	_rain.amount = 1400
	_rain.lifetime = 1.2
	_rain.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 30, 40))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(16, 1, 16)
	pm.direction = Vector3(0.15, -1, 0.05)
	pm.spread = 3.0
	pm.initial_velocity_min = 16.0
	pm.initial_velocity_max = 20.0
	pm.gravity = Vector3(0, -9.8, 0)
	_rain.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.015, 0.45)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(0.7, 0.75, 0.8, 0.22)
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	qm.material = rm
	_rain.draw_pass_1 = qm
	add_child(_rain)
	_rain_snd = AudioStreamPlayer.new()
	_rain_snd.stream = Sound.get_stream("amb_rain")
	_rain_snd.bus = "Ambience"
	_rain_snd.volume_db = -80.0
	add_child(_rain_snd)
	_rain_snd.play()


func _lightning() -> void:
	var e := moon.light_energy
	var tw := create_tween()
	for i in 2:
		tw.tween_property(moon, "light_energy", 4.0, 0.04)
		tw.tween_property(moon, "light_energy", e, 0.12)
	await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
	Sound.play_2d("thunder_%d" % (randi() % 3), -14.0, "Ambience")


func _build_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.015, 0.02, 0.028)
	sm.sky_horizon_color = Color(0.07, 0.085, 0.1)
	sm.ground_horizon_color = Color(0.05, 0.06, 0.07)
	sm.ground_bottom_color = Color(0.01, 0.012, 0.015)
	sm.sun_angle_max = 0.0
	sm.sky_energy_multiplier = 1.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.13, 0.15, 0.19)
	env.ambient_light_energy = 0.75
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.12, 0.145)
	env.fog_light_energy = 1.0
	env.fog_density = 0.022
	env.fog_sky_affect = 0.85
	env.fog_aerial_perspective = 0.2
	env.volumetric_fog_enabled = Game.settings.get("volumetric_fog", true)
	env.volumetric_fog_density = 0.018
	env.volumetric_fog_albedo = Color(0.55, 0.6, 0.65)
	env.volumetric_fog_length = 48.0
	env.volumetric_fog_ambient_inject = 0.25
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.78
	env.adjustment_contrast = 1.06
	world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	moon = DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.82)
	moon.light_energy = 0.5
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 70.0
	moon.rotation_degrees = Vector3(-38, 35, 0)
	add_child(moon)
	Game.settings_changed.connect(func(): env.volumetric_fog_enabled = Game.settings.get("volumetric_fog", true))


## Surface vs. the spaces under the island: swap lighting so nothing leaks.
func set_space(s: String) -> void:
	space = s
	var under := s != "surface"
	moon.visible = not under
	env.background_mode = Environment.BG_COLOR if under else Environment.BG_SKY
	env.background_color = Color(0, 0, 0)
	env.ambient_light_color = Color(0.06, 0.07, 0.075) if under else Color(0.13, 0.15, 0.19)
	env.ambient_light_energy = 0.6 if under else 0.75
	env.fog_light_color = Color(0.02, 0.025, 0.03) if under else Color(0.1, 0.12, 0.145)
	env.fog_density = 0.04 if under else 0.022
	ocean.visible = not under


## Fade, move the player, change space. Used by cave mouths, ladders, hatches.
func travel(pos: Vector3, yaw: float, to_space: String, ambience := "") -> void:
	player.freeze(true)
	await hud.fade_black(true, 0.5)
	player.place(pos, yaw)
	_floor_pos = pos
	_dry_pos = pos if to_space == "surface" else Vector3.ZERO
	set_space(to_space)
	if ambience != "":
		Sound.set_zone(ambience)
	await get_tree().create_timer(0.35).timeout
	await hud.fade_black(false, 0.7)
	player.freeze(false)


func checkpoint(id: String) -> void:
	Game.save_checkpoint(id)


func objective(id: String) -> void:
	Game.set_objective(id)


# ------------------------------------------------------------------ navigation
func _bake_navigation() -> void:
	var map := get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, 0.3)
	NavigationServer3D.map_set_cell_height(map, 0.25)
	var regions := {
		"surface": AABB(Vector3(-120, -4, -72), Vector3(170, 30, 180)),
		"caves": AABB(CAVE_ORIGIN + Vector3(-40, -6, -100), Vector3(80, 20, 110)),
		"chamber": AABB(CHAMBER_ORIGIN + Vector3(-22, -4, -22), Vector3(44, 14, 44)),
		"annex": AABB(ANNEX_ORIGIN + Vector3(-30, -4, -30), Vector3(60, 12, 60)),
	}
	for key in regions:
		var nm := NavigationMesh.new()
		nm.cell_size = 0.3
		nm.cell_height = 0.25
		nm.agent_radius = 0.6
		nm.agent_height = 2.25
		nm.agent_max_climb = 0.5
		nm.agent_max_slope = 40.0
		nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		nm.geometry_collision_mask = B.LAYER_WORLD | B.LAYER_NAVBLOCK
		nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
		nm.geometry_source_group_name = "navsrc_" + key
		nm.filter_baking_aabb = regions[key]
		var reg := NavigationRegion3D.new()
		reg.name = "Nav_" + key
		reg.navigation_mesh = nm
		add_child(reg)
		nav_regions[key] = reg
		var t0 := Time.get_ticks_msec()
		reg.bake_navigation_mesh(false)
		NavigationServer3D.map_force_update(map)
		if Game.debug_ai:
			print("[debug] nav ", key, " baked in ", Time.get_ticks_msec() - t0, " ms, polys: ", nm.get_polygon_count())


## The sea is the boundary: anyone who wades in is put back on the last dry
## ground. Because the tide moves this line, the tide decides what is reachable.
var _dry_pos := Vector3.ZERO
var _dry_timer := 0.0


var _floor_pos := Vector3.ZERO


func _physics_process(delta: float) -> void:
	if player == null or player.dead or not player.is_physics_processing():
		return
	var p := player.global_position
	# Safety net for every space: if the player ever falls out of the world, put them back.
	if player.is_on_floor():
		_floor_pos = p
	elif _floor_pos != Vector3.ZERO and p.y < _floor_pos.y - 25.0:
		player.global_position = _floor_pos + Vector3(0, 0.3, 0)
		player.velocity = Vector3.ZERO
		return
	if space != "surface":
		return
	var sea: float = ocean.position.y
	if p.y < sea + 0.1 and _dry_pos != Vector3.ZERO:
		Sound.play_at("splash", p, -4.0)
		if _dry_pos.y < sea + 0.4:
			# the tide has come back over the last dry spot: retreat to the checkpoint
			_dry_pos = checkpoints.get(Game.state.checkpoint, checkpoints["dock_start"])[0]
		player.global_position = _dry_pos
		player.velocity = Vector3.ZERO
		hud.toast("The water is black and freezing. You wouldn't last a minute in it.")
	elif player.is_on_floor() and p.y > sea + 0.6:
		_dry_timer += delta
		if _dry_timer > 0.4:
			_dry_timer = 0.0
			_dry_pos = p


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not hud.reading and not player.dead and not Game.is_transitioning():
		pause_menu.toggle()
		get_viewport().set_input_as_handled()
