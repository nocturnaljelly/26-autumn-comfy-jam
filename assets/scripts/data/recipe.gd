class_name Recipe
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var ingredients: Array[Ingredient] = []

@export_group("Visuals")
@export var color: Color = Color.WHITE
@export var icon: Texture2D


func matches(mix: Array[Ingredient]) -> bool:
	return Recipe.count_ingredients(mix) == Recipe.count_ingredients(ingredients)

func get_formula() -> String:
	var names: PackedStringArray = []
	for ingredient in ingredients:
		names.append(ingredient.display_name)
	return " + ".join(names)

static func count_ingredients(list: Array[Ingredient]) -> Dictionary:
	var counts := {}
	for ingredient in list:
		if ingredient:
			counts[ingredient.id] = counts.get(ingredient.id, 0) + 1
	return counts

func _to_string() -> String:
	return "Recipe(%s)" % id
