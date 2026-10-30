extends Node3D
## THE SHIP GRAVEYARD (optional): the research vessel MV Pelagic and the boats
## that came looking for her, beached on the west shore below Blackwood.
## The cargo hold shows what Project Morrow did to the crew; the radio room
## holds the Pelagic's mayday — part two of the last recording.

const C := Vector3(-98, 0, 46)

var level: Node


func build(lv: Node) -> void:
	level = lv
	add_to_group("navsrc_surface")
	var g := Terrain.height(C.x, C.z)
	var base := C + Vector3(0, g, 0)
	level.checkpoints["graveyard"] = [base + Vector3(12, 0.3, 0), -90.0, "surface"]
	Zone.make(self, base + Vector3(0, 3, 0), Vector3(36, 12, 40), {"ambience": "dock", "on_enter": func(_b):
		level.chapter("ch_graveyard")
		if not Game.has_flag("graveyard_line"):
			Game.set_flag("graveyard_line")
			level.hud.elias("graveyard", 1.5)})
	_hulk(base)
	_wrecks(base)
	for spot in [Vector3(-8, 0, 14), Vector3(-12, 0, -10), Vector3(4, 0, 17)]:
		level.horror.apparition(base + spot + Vector3(0, -0.5, 0), PI * 0.5, {"range": 40.0, "caption": "[a crewman standing in the surf — gone]"})


func _hulk(base: Vector3) -> void:
	## The Pelagic lies on her side; you enter the hold through a torn plate.
	var hull := B.mat("metal_rust", Color(0.75, 0.75, 0.75), 0.6, {"metallic": 0.4})
	var deck := B.mat("wood_dark", Color(0.8, 0.8, 0.8), 0.6)
	var ship := Node3D.new()
	add_child(ship)
	ship.position = base + Vector3(-2, 0, 0)
	ship.rotation_degrees = Vector3(0, 8, 0)
	# the hold: a long room you can walk into
	var hold := B.room(ship, Vector3(0, 0, 0), Vector3(6, 3.2, 14), {"wall": hull, "outer": hull, "floor": deck, "ceiling": hull, "surface": "metal",
		"openings": [{"side": "e", "at": 3.0, "w": 1.8, "h": 2.6}]})
	B.box(ship, Vector3(0, 4.2, 0), Vector3(7.2, 1.6, 16), hull, {"collide": false})                  # upper hull
	for z in [-7.5, 7.5]:
		B.box(ship, Vector3(0, 2.5, z * 1.1), Vector3(5.5, 4.5, 2.5), hull, {"collide": false})        # bow / stern masses
	B.label(ship, Vector3(3.75, 3.6, -3), "PELAGIC", 70, Color(0.85, 0.8, 0.7), Vector3(0, 90, 0))
	B.omni(ship, Vector3(0, 2.6, 2), Color(0.5, 0.65, 0.7), 0.35, 8.0)
	Zone.make(ship, Vector3(0, 1.5, 0), Vector3(5.8, 3, 13.8), {"ambience": "interior", "reverb": 0.35, "on_enter": func(_b):
		if not Game.has_flag("cargo_line"):
			Game.set_flag("cargo_line")
			level.hud.elias("cargo", 1.0)})
	# the cargo: a net of crew, ears taken
	var net := Vector3(-1.4, 0, -3.0)
	for i in 4:
		P.corpse(ship, net + Vector3(randf_range(-0.6, 0.6), 0.1 + i * 0.12, randf_range(-1.2, 1.2)), randf() * 360.0, "lie")
	var cover := B.sphere(ship, net + Vector3(0, 0.5, 0), 0.5, B.mat("rope", Color.WHITE, 2.0))
	cover.scale = Vector3(2.0, 0.9, 3.0)
	P.examine(ship, net + Vector3(0, 0.8, 0), Vector3(2.2, 1.4, 3.0), "cargo_net")
	P.smear(ship, Vector3(-2.95, 1.4, -1.0), Vector2(1.6, 1.2), 90)
	P.smear(ship, Vector3(-2.95, 0.8, 2.5), Vector2(0.8, 1.4), 90)
	P.crate(ship, Vector3(1.8, 0, -5.5), 12)
	P.crate(ship, Vector3(1.6, 0.8, -5.4), 30, 0.6)
	P.barrel(ship, Vector3(2.2, 0, 5.4))
	P.note(ship, Vector3(1.5, 1.0, 5.0), "mayday_log", 0)
	P.table(ship, Vector3(1.6, 0, 5.2), 0, Vector2(1.2, 0.7))
	# the radio: switches itself on as you approach, screams, then gives up the mayday
	var radio := P.radio_set(ship, Vector3(1.4, 0.8, 5.5), 180, true)
	P.examine(ship, Vector3(1.4, 1.0, 5.5), Vector3(0.6, 0.4, 0.5), "ship_radio")
	var rec := Recordable.make(ship, Vector3(1.4, 1.1, 5.5), "mayday", "", {"radius": 4.5, "active_flag": "graveyard_radio"})
	Zone.make(ship, Vector3(0.5, 1.5, 4.0), Vector3(4, 3, 3), {"once": true, "block": "graveyard_radio", "on_enter": func(_b):
		Sound.play_at("radio_burst", radio.global_position, 4.0)
		await get_tree().create_timer(0.3).timeout
		level.horror.jumpscare(level.player.head.global_position - level.player.camera.global_transform.basis.z * 1.1, 1)
		await get_tree().create_timer(1.2).timeout
		Game.set_flag("graveyard_radio")
		Sound.play_at(Story.RECORDINGS["mayday"].sound, radio.global_position, 0.0, {"bus": "Voice"})
		Sound.say(Story.RECORDINGS["mayday"].caption, "radio", 6.0)
		var t := Timer.new()
		t.wait_time = 20.0
		t.autostart = true
		radio.add_child(t)
		t.timeout.connect(func(): Sound.play_at(Story.RECORDINGS["mayday"].sound, radio.global_position, -4.0, {"bus": "Voice"}))
		level.hud.toast("The radio is repeating the mayday. Record it [R].", 4.0)})


func _wrecks(base: Vector3) -> void:
	var hull := B.mat("wood_dark", Color(0.65, 0.65, 0.7), 0.6)
	for spec in [[Vector3(-14, -1.0, 12), 25.0, -18.0], [Vector3(-10, -1.4, -14), -40.0, 22.0], [Vector3(6, -0.3, 16), 80.0, -30.0]]:
		var w := Node3D.new()
		add_child(w)
		w.position = base + spec[0]
		w.rotation_degrees = Vector3(0, spec[1], spec[2])
		B.box(w, Vector3(0, 0.6, 0), Vector3(2.6, 0.2, 7), hull, {})
		for sx in [-1, 1]:
			B.box(w, Vector3(sx * 1.3, 1.2, 0), Vector3(0.15, 1.3, 7), hull, {"collide": false})
		B.box(w, Vector3(0, 2.5, -1.0), Vector3(0.15, 4.0, 0.15), hull, {"collide": false})
	var rock := B.mat("stone_wet", Color.WHITE, 0.35)
	for i in 10:
		B.rock(self, base + Vector3(randf_range(-16, 16), -0.3, randf_range(-18, 18)), Vector3.ONE * randf_range(0.6, 1.8), i, rock, true, randf() * TAU)
