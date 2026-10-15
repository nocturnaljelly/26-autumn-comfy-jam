class_name RecipeBook
extends Resource

@export var recipes: Array[Recipe] = []
@export var ingredients: Array[Ingredient] = []


func get_recipe(id: StringName) -> Recipe:
	for recipe in recipes:
		if recipe and recipe.id == id:
			return recipe
	return null

func get_number(recipe: Recipe) -> int:
	return recipes.find(recipe) + 1

func get_random_recipe(exclude: Recipe = null) -> Recipe:
	var options := recipes.filter(func(recipe: Recipe) -> bool: return recipe != exclude)
	return options.pick_random() if not options.is_empty() else exclude

func create_runtime_copy() -> RecipeBook:
	var copy: RecipeBook = duplicate()
	var runtime_recipes: Array[Recipe] = []
	for recipe in recipes:
		runtime_recipes.append(recipe.create_runtime_copy())
	copy.recipes = runtime_recipes
	return copy

func reset_from(base: RecipeBook) -> void:
	for recipe in recipes:
		var original := base.get_recipe(recipe.id)
		if original:
			recipe.ingredients = original.ingredients.duplicate()

func change_random_recipe(exclude_id: StringName = &"") -> Recipe:
	var options := recipes.filter(func(recipe: Recipe) -> bool: return recipe.has_variants())
	if options.size() > 1:
		options = options.filter(func(recipe: Recipe) -> bool: return recipe.id != exclude_id)
	if options.is_empty():
		return null
	var recipe: Recipe = options.pick_random()
	recipe.apply_random_variant()
	return recipe

func get_variant_warnings(max_ingredients: int) -> PackedStringArray:
	var warnings: PackedStringArray = []
	for recipe in recipes:
		var original := Recipe.count_ingredients(recipe.ingredients)
		for variant in recipe.variants:
			if not variant or variant.ingredients.is_empty():
				warnings.append("%s has an empty variant" % recipe.display_name)
				continue
			var counts := Recipe.count_ingredients(variant.ingredients)
			if variant.ingredients.size() > max_ingredients:
				warnings.append("%s variant %s needs more than %d ingredients" % [recipe.display_name, Recipe.format_ingredients(variant.ingredients), max_ingredients])
			if counts == original:
				warnings.append("%s variant %s is the same as the original" % [recipe.display_name, Recipe.format_ingredients(variant.ingredients)])
			for other in recipes:
				if other != recipe and counts == Recipe.count_ingredients(other.ingredients):
					warnings.append("%s variant %s is identical to %s" % [recipe.display_name, Recipe.format_ingredients(variant.ingredients), other.display_name])
	return warnings
