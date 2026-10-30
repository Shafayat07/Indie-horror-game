extends Node3D
## A Listener silhouette used as an apparition between the trees: a still copy
## of the real model that is gone when you look straight at it.

var kind := "listener"
var _model: Node3D


func _ready() -> void:
	_model = preload("res://scripts/enemy/listener_model.gd").new()
	add_child(_model)


func _process(delta: float) -> void:
	if visible and _model.head:
		_model.animate(delta, 0.0, null)


func vanish() -> void:
	queue_free()
