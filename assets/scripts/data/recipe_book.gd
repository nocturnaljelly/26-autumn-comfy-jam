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
