extends Light3D
## Unstable practical light: mostly steady, with occasional stutters.

var base := -1.0
var _t := 0.0
var _next := 2.0


func _ready() -> void:
	base = light_energy


func _process(delta: float) -> void:
	if base < 0.0:
		base = light_energy
	_t += delta
	if _t > _next:
		_t = 0.0
		_next = randf_range(1.5, 7.0)
		_stutter()


func _stutter() -> void:
	var tw := create_tween()
	for i in randi_range(2, 5):
		tw.tween_property(self, "light_energy", base * randf_range(0.05, 0.5), 0.04)
		tw.tween_property(self, "light_energy", base, randf_range(0.03, 0.12))
