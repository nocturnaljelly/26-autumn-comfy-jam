class_name Recipe
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var ingredients: Array[Ingredient] = []
@export var variants: Array[RecipeVariant] = []

@export_group("Visuals")
@export var color: Color = Color.WHITE
@export var icon: Texture2D


func matches(mix: Array[Ingredient]) -> bool:
	return Recipe.count_ingredients(mix) == Recipe.count_ingredients(ingredients)

func get_formula() -> String:
	return Recipe.format_ingredients(ingredients)

func create_runtime_copy() -> Recipe:
	var copy: Recipe = duplicate()
	copy.ingredients = ingredients.duplicate()
	return copy

func has_variants() -> bool:
	return variants.any(func(variant: RecipeVariant) -> bool: return variant and not variant.ingredients.is_empty())

func apply_random_variant() -> void:
	var current := Recipe.count_ingredients(ingredients)
	var options := variants.filter(func(variant: RecipeVariant) -> bool:
		return variant and not variant.ingredients.is_empty() and Recipe.count_ingredients(variant.ingredients) != current)
	if not options.is_empty():
		ingredients = options.pick_random().ingredients.duplicate()

static func count_ingredients(list: Array[Ingredient]) -> Dictionary:
	var counts := {}
	for ingredient in list:
		if ingredient:
			counts[ingredient.id] = counts.get(ingredient.id, 0) + 1
	return counts

static func format_ingredients(list: Array[Ingredient]) -> String:
	var names: PackedStringArray = []
	for ingredient in list:
		if ingredient:
			names.append(ingredient.display_name)
	return " + ".join(names)

func _to_string() -> String:
	return "Recipe(%s)" % id
