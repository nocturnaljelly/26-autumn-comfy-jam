class_name Customer
extends Resource

enum CustomerExpression { NEUTRAL, SATISFIED, DISSATISFIED }

@export var id: StringName
@export var display_name: String = ""
@export var normal_sprites: Array[Texture2D] = []
@export var alternate_sprites: Array[Texture2D] = []
@export_range(0.0, 1.0, 0.05) var order_change_chance := 0.3
@export_range(0.0, 1.0, 0.05) var sprite_change_chance := 0.3

func get_random_sprite(expression: CustomerExpression, exclude: Texture2D = null) -> Texture2D:
	var options: Array[Texture2D] = [normal_sprites[expression], alternate_sprites[expression]]
	options = options.filter(func(texture: Texture2D) -> bool: return texture and texture != exclude)
	return options.pick_random() if not options.is_empty() else exclude

func get_expression_sprite(current_texture: Texture2D, expression: CustomerExpression) -> Texture2D:
	if current_texture in alternate_sprites: return alternate_sprites[expression]
	return normal_sprites[expression]

func _to_string() -> String:
	return "Customer(%s)" % id
