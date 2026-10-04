class_name Recipe
extends Resource

enum Change { REMOVE, ADD, REPLACE }

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

func create_runtime_copy() -> Recipe:
	var copy: Recipe = duplicate()
	copy.ingredients = ingredients.duplicate()
	return copy

func apply_random_change(pool: Array[Ingredient], max_ingredients: int) -> void:
	var options: Array[Change] = []
	if ingredients.size() > 1:
		options.append(Change.REMOVE)
	if ingredients.size() < max_ingredients:
		options.append(Change.ADD)
	if not ingredients.is_empty():
		options.append(Change.REPLACE)
	match options.pick_random():
		Change.REMOVE:
			ingredients.remove_at(randi() % ingredients.size())
		Change.ADD:
			ingredients.insert(randi_range(0, ingredients.size()), pool.pick_random())
		Change.REPLACE:
			var index := randi() % ingredients.size()
			var current := ingredients[index]
			ingredients[index] = pool.filter(func(other: Ingredient) -> bool: return other.id != current.id).pick_random()

static func count_ingredients(list: Array[Ingredient]) -> Dictionary:
	var counts := {}
	for ingredient in list:
		if ingredient:
			counts[ingredient.id] = counts.get(ingredient.id, 0) + 1
	return counts

func _to_string() -> String:
	return "Recipe(%s)" % id
