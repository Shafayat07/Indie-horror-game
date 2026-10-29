class_name Interactable
extends StaticBody3D
## Generic interactable: a collision volume on the "interact" layer with a
## prompt. Behaviour is supplied by connecting to `used`, so puzzle logic can
## live with the area that owns it.

signal used(player: Node)

@export var prompt := "Use"
@export var enabled := true
## Optional flag that must be set before this can be used; otherwise `locked_text` shows.
var require_flag := ""
var locked_text := ""
var once := false


static func make(parent: Node3D, pos: Vector3, size: Vector3, prompt_text: String, cb: Callable = Callable()) -> Interactable:
	var it := Interactable.new()
	it.prompt = prompt_text
	it.collision_layer = B.LAYER_INTERACT
	it.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	it.add_child(cs)
	parent.add_child(it)
	it.position = pos
	if cb.is_valid():
		it.used.connect(cb)
	return it


func get_prompt() -> String:
	return prompt


func can_interact() -> bool:
	return enabled and is_visible_in_tree()


func interact(player: Node) -> void:
	if not can_interact():
		return
	if require_flag != "" and not Game.has_flag(require_flag):
		if locked_text != "":
			player.hud.toast(locked_text)
		return
	if once:
		enabled = false
	used.emit(player)
