extends Control

const CUP_CAPACITY := 4

@export var recipe_book: RecipeBook
@export var fade_duration := 0.8

var menu: RecipeBook
var order: Recipe
var cup: Array[Ingredient] = []
var facing_menu := false
var _fade_tween: Tween

@onready var counter_view: Control = %CounterView
@onready var customer_sprite: TextureRect = %CustomerSprite
@onready var order_label: Label = %OrderLabel
@onready var cup_label: Label = %CupLabel
@onready var ingredient_buttons: Container = %IngredientButtons
@onready var serve_button: Button = %ServeButton
@onready var clear_button: Button = %ClearButton
@onready var menu_view: Control = %MenuView
@onready var menu_label: Label = %MenuLabel
@onready var turn_button: Button = %TurnButton


func _ready() -> void:
	menu = recipe_book.create_runtime_copy()
	for ingredient in menu.ingredients:
		var button := AnimatedButton.new()
		button.text = ingredient.display_name
		button.pressed.connect(_add_ingredient.bind(ingredient))
		ingredient_buttons.add_child(button)
	serve_button.pressed.connect(_serve)
	clear_button.pressed.connect(_clear_cup)
	turn_button.pressed.connect(_turn)
	customer_sprite.modulate.a = 0.0
	_update_menu()
	_show_view()
	_next_customer()

func _turn() -> void:
	facing_menu = not facing_menu
	if facing_menu:
		menu.reset_from(recipe_book)
		menu.change_random_recipe(CUP_CAPACITY)
		_update_menu()
	_show_view()

func _next_customer() -> void:
	order = menu.get_random_recipe()
	_update_order_label()
	_update_controls()
	_fade_customer(1.0)

func _serve() -> void:
	var correct := order.matches(cup)
	order_label.text = "Correct!" if correct else "Wrong! That's not number %d." % menu.get_number(order)
	order = null
	_clear_cup()
	await _fade_customer(0.0)
	_next_customer()

func _add_ingredient(ingredient: Ingredient) -> void:
	if cup.size() < CUP_CAPACITY:
		cup.append(ingredient)
		_update_controls()

func _clear_cup() -> void:
	cup.clear()
	_update_controls()

func _fade_customer(alpha: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(customer_sprite, "modulate:a", alpha, fade_duration)
	await _fade_tween.finished

func _show_view() -> void:
	counter_view.visible = not facing_menu
	menu_view.visible = facing_menu
	turn_button.text = "Back to customer" if facing_menu else "Look at menu"

func _update_order_label() -> void:
	order_label.text = "Customer wants number %d" % menu.get_number(order)

func _update_menu() -> void:
	var lines: PackedStringArray = []
	for recipe in menu.recipes:
		lines.append("%d. %s = %s" % [menu.get_number(recipe), recipe.get_formula(), recipe.display_name])
	menu_label.text = "\n".join(lines)

func _update_controls() -> void:
	var names: PackedStringArray = []
	for ingredient in cup:
		names.append(ingredient.display_name)
	cup_label.text = "Cup: " + (" + ".join(names) if not names.is_empty() else "empty")
	for button: Button in ingredient_buttons.get_children():
		button.disabled = cup.size() >= CUP_CAPACITY
	serve_button.disabled = order == null or cup.is_empty()
	clear_button.disabled = cup.is_empty()
