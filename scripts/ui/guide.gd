extends Control
## Wayfinding: an amber marker on screen pointing at the next thing to do
## (with distance, clamped to the screen edge when it's behind you), small
## markers for optional places you've unlocked but not visited, and a panel
## under the objective listing those places and the last checkpoint.
## Targets in another space (caves, chamber, annex, roost) route through the
## way in or out. Can be turned off in Options.

const AMBER := Color(1.0, 0.72, 0.32)
const DIM := Color(0.78, 0.8, 0.78, 0.8)

const OPTIONAL := [
	# [label, position, unlocked by, visited flag, space]
	["Blackwood and the old radio tower", Vector3(-57, 0, 33), "entered_settlement", "ch_forest", "surface"],
	["The Ship Graveyard", Vector3(-96, 0, 46), "entered_settlement", "ch_graveyard", "surface"],
	["Low Vey (exposed at low tide)", Vector3(67, 0, -20), "tide_out", "ch_lowvey", "surface"],
	["The iron door marked MORROW", Vector3.INF, "ch_caves", "ch_annex", "caves"],
]
const HINTS := {
	"Blackwood and the old radio tower": "west of the village, along the forest path",
	"The Ship Graveyard": "the west shore, below Blackwood",
	"Low Vey (exposed at low tide)": "the east shore, below the cliffs",
	"The iron door marked MORROW": "a side passage in the tidal caves",
}
const CHECKPOINT_NAMES := {
	"dock_start": "The dock", "dock_recorder": "The maintenance shed", "settlement": "The settlement",
	"settlement_key": "The blue house", "station": "Weather station gate", "station_power": "Generator room",
	"station_relays": "Relay corridor", "station_transmit": "Monitoring room", "caves": "Cave mouth",
	"caves_gate": "The iron seal", "lighthouse": "The lighthouse", "chamber": "Transmitter chamber",
	"forest": "Kell's hut", "roost": "The roost", "kell_chase": "Blackwood", "graveyard": "Ship graveyard",
	"annex": "The annex", "aftermath": "The lighthouse", "ending_boat": "The dock",
}

var level: Node
var _panel: Label
var _font: Font
var _nodes := {}          # interactable prompt -> node
var _target := []         # [world position, label] or []
var _scan_t := 0.0


func setup(lv: Node) -> void:
	level = lv
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UITheme.heading_font()
	_panel = UITheme.lbl("", 15, DIM)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_index()


func _index() -> void:
	_nodes.clear()
	for n in get_tree().get_nodes_in_group("interactable"):
		_nodes[(n as Interactable).prompt] = n


func _node(prefix: String) -> Node3D:
	for k in _nodes:
		if (k as String).begins_with(prefix) and is_instance_valid(_nodes[k]) and (_nodes[k] as Node3D).is_visible_in_tree():
			return _nodes[k]
	return null


func _at(prefix: String, fallback: Vector3) -> Vector3:
	var n := _node(prefix)
	return n.global_position if n else fallback


## Which space a world position belongs to.
func _space_of(p: Vector3) -> String:
	if p.y > -100.0:
		return "surface"
	var best := "caves"
	var bd := INF
	for s in [["caves", level.CAVE_ORIGIN], ["chamber", level.CHAMBER_ORIGIN], ["roost", level.ROOST_ORIGIN], ["annex", level.ANNEX_ORIGIN]]:
		var d: float = p.distance_to(s[1])
		if d < bd:
			bd = d
			best = s[0]
	return best


func _objective_target() -> Array:
	var g := func(x: float, z: float, up := 0.0) -> Vector3: return Vector3(x, Terrain.height(x, z) + up, z)
	match Game.state.get("objective", ""):
		"leave_boat": return [Vector3(0, 1.6, 100), "The dock"]
		"find_shed", "take_recorder": return [_at("Take the field recorder", g.call(8, 72, 1.0)), "Maintenance shed"]
		"try_listen", "record_echo": return [g.call(8, 72, 1.0), "Maintenance shed"]
		"go_inland": return [Vector3(0, 5.2, 56), "The settlement"]
		"find_key":
			if Game.has_flag("heard_teahouse"):
				return [_at("Open the clock case", Vector3(5.8, 5.2, 39.5)), "The blue house"]
			return [Vector3(-5.8, 5.2, 51), "The teahouse"]
		"reach_station": return [Vector3(-44, 7.5, -8), "Weather station gate"]
		"restore_power":
			if Game.has_flag("fuel_open"):
				return [_at("Pull the starter cord", Vector3(-65, 7.5, -5.4)), "Generator: starter cord"]
			return [_at("Open the fuel valve", Vector3(-65, 7.5, -5.4)), "Generator room: fuel valve"]
		"find_sequence":
			if Game.has_flag("heard_tape"):
				return [_at("Engage relay", Vector3(-57, 7.5, -12)), "Relays"]
			return [_at("Tape deck", Vector3(-58, 7.5, -8)), "Tape deck (listen with Q)"]
		"activate_transmitter": return [_at("Transmit the diagnostic report", Vector3(-54.4, 7.7, -13.6)), "Monitoring room"]
		"find_caves": return [Vector3(66, 0.5, -50.5), "Cave mouth"]
		"open_gate":
			if Game.has_recording("bell"):
				return [level.areas.caves._p(0.9, -34.8, 1.2), "The iron seal's horn"]
			return [_at("Drowned bell", level.areas.caves._p(-14.5, -31, 0.6)), "Drowned bell (listen with Q)"]
		"cross_caves": return [_at("Climb the iron stair", level.CAVE_ORIGIN + Vector3(0, 1, -84)), "Iron stair"]
		"release_seal": return [_at("Pull the seal release", level.areas.lighthouse.C + Vector3(0, 13, 0)), "Seal release lever (top floor)"]
		"descend": return [_at("Sealed hatch", level.areas.lighthouse.C + Vector3(0.3, 0.5, 0.2)), "The hatch"]
		"arm_transmitter": return [_at("Engage coupling", level.CHAMBER_ORIGIN + Vector3(0, 1, 0)), "Power couplings"]
		"choose": return [_at("TRANSMIT", level.CHAMBER_ORIGIN + Vector3(0, 1.2, 0)), "The console"]
		"return_boat", "leave": return [_at("Start the engine", Vector3(5.6, 2.5, 108.5)), "The boat"]
	return []


## If the target is in another space, point at the way there instead.
func _route(t: Array) -> Array:
	var here: String = level.space
	var there := _space_of(t[0])
	if here == there or (here == "annex" and there == "annex"):
		return t
	match here:
		"surface":
			if there == "chamber":
				return [_at("Sealed hatch", t[0]), "The hatch (to " + t[1] + ")"]
			if there == "roost":
				return [Vector3(-72, Terrain.height(-72, 61) + 1, 61), "The roost"]
			return [Vector3(66, 0.5, -50.5), "Cave mouth"]
		"caves":
			if there == "annex":
				return [_at("Iron door", t[0]), "Iron door — MORROW"]
			if there == "chamber" or t[0].distance_to(level.areas.lighthouse.C) < 25.0:
				return [_at("Climb the iron stair", t[0]), "Iron stair (to the lighthouse)"]
			return [_at("Go back out to the beach", t[0]), "Way out to the beach"]
		"chamber":
			return [_at("Climb back up to the lighthouse", t[0]), "Ladder up"]
		"annex":
			return [_at("Climb back up to the caves", t[0]), "Ladder up to the caves"]
		"roost":
			return [_at("Climb back out", t[0]), "Way out"]
	return t


func _process(delta: float) -> void:
	_scan_t -= delta
	if _scan_t <= 0.0:
		_scan_t = 2.0
		_index()
	var on: bool = Game.settings.get("nav_helper", true)
	var hud: Node = level.hud
	visible = on and not hud.reading and not get_tree().paused and hud.visible and not hud.in_cutscene
	if not visible:
		return
	var t := _objective_target()
	_target = _route(t) if not t.is_empty() else []
	# the panel under the objective: optional places, last checkpoint
	var lines := PackedStringArray()
	for o in OPTIONAL:
		if Game.has_flag(o[2]) and not Game.has_flag(o[3]):
			lines.append("◦ Optional: %s — %s" % [o[0], HINTS[o[0]]])
	var cp: String = CHECKPOINT_NAMES.get(Game.state.get("checkpoint", ""), "")
	if cp != "":
		lines.append("Last checkpoint: " + cp)
	_panel.text = "\n".join(lines)
	var obj: Control = hud._objective
	_panel.position = obj.global_position + Vector2(8, obj.size.y + 6)
	_panel.size = Vector2(620, 0)
	queue_redraw()


func _draw() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null or level.player == null:
		return
	var vp := get_viewport_rect().size
	if not _target.is_empty():
		_marker(cam, vp, _target[0], _target[1], AMBER, true)
	for o in OPTIONAL:
		if Game.has_flag(o[2]) and not Game.has_flag(o[3]) and o[4] == level.space and o[1] != Vector3.INF:
			var p: Vector3 = o[1]
			p.y = Terrain.height(p.x, p.z) + 2.0
			if p.distance_to(cam.global_position) < 160.0:
				_marker(cam, vp, p, o[0], DIM, false)


func _marker(cam: Camera3D, vp: Vector2, world: Vector3, label: String, col: Color, main: bool) -> void:
	var dist := cam.global_position.distance_to(world)
	var behind := cam.is_position_behind(world)
	var sp := cam.unproject_position(world)
	if behind:
		sp = vp - sp
	var m := vp * Vector2(0.06, 0.1)
	var inside := not behind and sp.x > m.x and sp.x < vp.x - m.x and sp.y > m.y and sp.y < vp.y - m.y
	if not inside:
		if not main:
			return
		var c := vp * 0.5
		var d := sp - c
		if behind and d.length() < 1.0:
			d = Vector2(0, 1)
		var k: float = min((vp.x * 0.5 - m.x) / max(abs(d.x), 0.001), (vp.y * 0.5 - m.y) / max(abs(d.y), 0.001))
		sp = c + d * k
	var r := 9.0 if main else 5.0
	if main:
		draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -r), sp + Vector2(r, 0), sp + Vector2(0, r), sp + Vector2(-r, 0)]), col)
		draw_polyline(PackedVector2Array([sp + Vector2(0, -r - 3), sp + Vector2(r + 3, 0), sp + Vector2(0, r + 3), sp + Vector2(-r - 3, 0), sp + Vector2(0, -r - 3)]), Color(0, 0, 0, 0.6), 2.0)
	else:
		draw_arc(sp, r, 0, TAU, 16, col, 2.0)
	var text := "%s  %d m" % [label, int(dist)] if main else label
	var fs := 17 if main else 14
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tp := sp + Vector2(-w * 0.5, r + 20)
	tp.x = clamp(tp.x, 8.0, vp.x - w - 8.0)
	tp.y = clamp(tp.y, 20.0, vp.y - 8.0)
	draw_string(_font, tp + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.8))
	draw_string(_font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
