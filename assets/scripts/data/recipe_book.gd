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

func get_random_recipe() -> Recipe:
	return recipes.pick_random() if not recipes.is_empty() else null

func create_runtime_copy() -> RecipeBook:
	var copy: RecipeBook = duplicate()
	var runtime_recipes: Array[Recipe] = []
	for recipe in recipes:
		runtime_recipes.append(recipe.create_runtime_copy())
	copy.recipes = runtime_recipes
	return copy

func reset_from(base: RecipeBook) -> void:
	for i in recipes.size():
		recipes[i].ingredients = base.recipes[i].ingredients.duplicate()

func change_random_recipe(max_ingredients: int) -> Recipe:
	var recipe := get_random_recipe()
	if recipe:
		recipe.apply_random_change(ingredients, max_ingredients)
	return recipe
