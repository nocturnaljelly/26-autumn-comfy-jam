extends Control

@export_file("*.tscn") var main_menu: String
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		SceneTransition.change_scene(main_menu, 3.0)
