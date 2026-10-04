class_name Customer
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var sprite: Texture2D
@export_range(0.0, 1.0, 0.05) var order_change_chance := 0.3


func _to_string() -> String:
	return "Customer(%s)" % id
