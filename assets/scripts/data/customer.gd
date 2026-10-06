class_name Customer
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var sprite: Texture2D
@export var alternate_sprites: Array[Texture2D] = []
@export_range(0.0, 1.0, 0.05) var order_change_chance := 0.3
@export_range(0.0, 1.0, 0.05) var sprite_change_chance := 0.3


func get_random_sprite(exclude: Texture2D = null) -> Texture2D:
	var options: Array[Texture2D] = [sprite]
	options.append_array(alternate_sprites)
	options = options.filter(func(texture: Texture2D) -> bool: return texture and texture != exclude)
	return options.pick_random() if not options.is_empty() else exclude

func _to_string() -> String:
	return "Customer(%s)" % id
