class_name Ingredient
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Visuals")
@export var color: Color = Color.WHITE
@export var icon: Texture2D


func _to_string() -> String:
	return "Ingredient(%s)" % id
