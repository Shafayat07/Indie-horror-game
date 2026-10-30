extends Node
## Test driver. Run with:
##   godot --path . res://tests/driver.tscn -- --cp=dock_start --flags=a,b --shots=x,y,z,yaw,pitch;...
## Options:
##   --cp=<checkpoint>        checkpoint to spawn at
##   --flags=a,b              progression flags to set first
##   --obj=<objective>        objective to set
##   --recs=id@x@y@z,...      recordings to give
##   --shots=x,y,z,yaw,pitch;...  camera poses to screenshot (relative to world)
##   --out=<dir>              screenshot directory
##   --scenario=<name>        run a scripted scenario from tests/scenarios.gd
##   --wait=<seconds>         settle time before shots

var args := {}
var level: Node


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	await get_tree().process_frame
	await get_tree().process_frame
	Game.reset_state()
	for f in str(args.get("flags", "")).split(",", false):
		Game.state.flags[f] = true
	if args.has("obj"):
		Game.state.objective = args.obj
	for r in str(args.get("recs", "")).split(",", false):
		var parts := r.split("@")
		Game.state.recordings.append({"id": parts[0], "origin": [float(parts[1]), float(parts[2]), float(parts[3])]})
	Game.state.checkpoint = args.get("cp", "dock_start")
	Game.save_checkpoint(Game.state.checkpoint)
	var t0 := Time.get_ticks_msec()
	get_tree().change_scene_to_file("res://scenes/island.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	level = get_tree().current_scene
	print("[driver] level built in %d ms" % (Time.get_ticks_msec() - t0))
	await get_tree().create_timer(float(args.get("wait", "1.5"))).timeout
	if args.has("capture"):   # --capture=t1,t2,...  seconds after start: save frames during a scenario
		var out: String = args.get("out", "/tmp/tide_shots")
		DirAccess.make_dir_recursive_absolute(out)
		for t in str(args.capture).split(","):
			get_tree().create_timer(float(t)).timeout.connect(func():
				get_viewport().get_texture().get_image().save_png("%s/cap_%s.png" % [out, t]))
	if args.has("scenario"):
		var sc = load("res://tests/scenarios.gd").new()
		add_child(sc)
		var ok: bool = await sc.run(args.scenario, level)
		print("[driver] scenario %s: %s" % [args.scenario, "PASS" if ok else "FAIL"])
	if args.has("shots"):
		await _shots(args.shots)
	print("[driver] done; objective=", Game.state.objective, " flags=", Game.state.flags.keys())
	get_tree().quit()


func _shots(spec: String) -> void:
	var out: String = args.get("out", "/tmp/tide_shots")
	DirAccess.make_dir_recursive_absolute(out)
	var i := 0
	var p: Node3D = level.player
	level.listener.hunt_enabled = false
	level.listener.sight = 0.0
	if args.has("nohud"):
		level.hud.visible = false
	if args.has("listener"):
		var v := str(args.listener).split(",")
		level.listener.activate(Vector3(float(v[0]), float(v[1]), float(v[2])), [])
		level.listener.rotation_degrees.y = float(v[3])
		level.listener.frozen = true
	for s in spec.split(";", false):
		var v := s.split(",")
		if v.size() >= 5:
			p.freeze(true)
			p.set_physics_process(false)
			p.global_position = Vector3(float(v[0]), float(v[1]) - 1.62, float(v[2]))
			p.rotation.y = deg_to_rad(float(v[3]))
			p.head.rotation.x = deg_to_rad(float(v[4]))
			p.head.position.y = 1.62
		if v.size() >= 7 and v[6] == "noshadow":
			p.flashlight.shadow_enabled = false
		if v.size() >= 6 and v[5] == "light":
			p.flashlight.light_energy = 2.4
			p.flash_pivot.global_transform = p.camera.global_transform
		for k in 12:
			await get_tree().process_frame
		print("[driver] flash e=", p.flashlight.light_energy, " pos=", p.flashlight.global_position, " fwd=", -p.flashlight.global_transform.basis.z, " vis=", p.flashlight.is_visible_in_tree())
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/shot_%02d.png" % [out, i])
		print("[driver] shot ", i)
		print("[perf] shot %d draws=%d objects=%d prims=%dk lights=%d" % [i, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000, get_tree().root.find_children("*", "Light3D", true, false).filter(func(l): return l.visible and l.is_visible_in_tree()).size()])
		i += 1
