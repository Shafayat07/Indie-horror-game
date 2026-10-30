extends Node
## Renders the main menu after a few seconds and saves a screenshot.
func _ready() -> void:
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	await get_tree().process_frame
	get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
	await get_tree().create_timer(4.0).timeout
	get_viewport().get_texture().get_image().save_png("/tmp/tide_shots/menu.png")
	get_tree().quit()
