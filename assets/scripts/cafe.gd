extends Control

const CUP_CAPACITY := 4
const HIGHLIGHT_COLOR := "#ffd27a"
enum View { CUSTOMERS, PREP }

@export var recipe_book: RecipeBook
@export var customers: Array[Customer] = []

var menu: RecipeBook
var cup: Array[Ingredient] = []
var current_view := View.CUSTOMERS
var facing_menu := false

@onready var counter_view: Control = %CounterView
@onready var customer_slots: Container = %CustomerSlots
@onready var arrival_timer: Timer = %ArrivalTimer
@onready var cup_label: RichTextLabel = %CupLabel
@onready var ingredient_buttons: Container = %IngredientButtons
@onready var clear_button: Button = %ClearButton
@onready var customer_view: Control = %CustomerView
@onready var to_prep_button: Button = $CounterView/CustomerView/ToPrepButton
@onready var prep_view: Control = %PrepView
@onready var to_customers_button: Button = $CounterView/PrepView/ToCustomersButton
@onready var menu_view: Control = %MenuView
@onready var menu_label: RichTextLabel = %MenuLabel
@onready var turn_button: Button = %TurnButton


func _ready() -> void:
	menu = recipe_book.create_runtime_copy()
	for ingredient in menu.ingredients:
		var button := AnimatedButton.new()
		button.text = ingredient.display_name
		button.pressed.connect(_add_ingredient.bind(ingredient))
		ingredient_buttons.add_child(button)
	for slot in _slots():
		slot.plate_button.pressed.connect(_serve.bind(slot))
	clear_button.pressed.connect(_clear_cup)
	turn_button.pressed.connect(_turn)
	arrival_timer.timeout.connect(_seat_next_customer)
	to_prep_button.pressed.connect(_show_view.bind(View.PREP))
	to_customers_button.pressed.connect(_show_view.bind(View.CUSTOMERS))
	menu_view.visible = false
	_update_menu()
	_show_view(View.CUSTOMERS)
	_seat_next_customer()
	_update_controls()

func _turn() -> void:
	facing_menu = not facing_menu
	if facing_menu:
		menu.reset_from(recipe_book)
		menu.change_random_recipe(CUP_CAPACITY)
		_update_menu()
	else:
		for slot in _slots():
			if slot.order and randf() < slot.customer.order_change_chance:
				slot.order = menu.get_random_recipe(slot.order)
				_update_order_text(slot)
	counter_view.visible = not facing_menu
	menu_view.visible = facing_menu
	turn_button.text = "Back to prep" if facing_menu else "Look at menu"

func _slots() -> Array[CustomerSlot]:
	var slots: Array[CustomerSlot] = []
	slots.assign(customer_slots.get_children())
	return slots

func _seat_next_customer() -> void:
	var free_slots := _slots().filter(func(slot: CustomerSlot) -> bool: return slot.is_free())
	if free_slots.is_empty():
		return
	var free_slot: CustomerSlot = free_slots.pick_random()
	free_slot.seat(_pick_customer(), menu.get_random_recipe())
	_update_order_text(free_slot)
	_update_controls()

func _pick_customer() -> Customer:
	var seated := _slots().map(func(slot: CustomerSlot) -> Customer: return slot.customer)
	var options := customers.filter(func(customer: Customer) -> bool: return not seated.has(customer))
	return options.pick_random() if not options.is_empty() else customers.pick_random()

func _serve(slot: CustomerSlot) -> void:
	var correct := slot.order.matches(cup)
	slot.say("[wave]Thanks![/wave]" if correct else "[shake rate=20 level=10]What is this?[/shake]")
	slot.leave()
	_clear_cup()

func _add_ingredient(ingredient: Ingredient) -> void:
	if cup.size() < CUP_CAPACITY:
		cup.append(ingredient)
		_update_controls()

func _clear_cup() -> void:
	cup.clear()
	_update_controls()

func _show_view(view: View) -> void:
	current_view = view
	customer_view.visible = view == View.CUSTOMERS
	prep_view.visible = view == View.PREP

func _update_order_text(slot: CustomerSlot) -> void:
	slot.say("[wave amp=40 freq=5][color=%s]Number %d[/color][/wave]" % [HIGHLIGHT_COLOR, menu.get_number(slot.order)])

func _update_menu() -> void:
	var lines: PackedStringArray = []
	for recipe in menu.recipes:
		var names: PackedStringArray = []
		for ingredient in recipe.ingredients:
			names.append(_ingredient_text(ingredient))
		lines.append("[color=%s]%d.[/color] %s = [wave amp=25 freq=3]%s[/wave]" % [HIGHLIGHT_COLOR, menu.get_number(recipe), " + ".join(names), recipe.display_name])
	menu_label.text = "\n".join(lines)

func _update_controls() -> void:
	var names: PackedStringArray = []
	for ingredient in cup:
		names.append(_ingredient_text(ingredient))
	if not names.is_empty():
		names[names.size() - 1] = "%s" % names[names.size() - 1]
	cup_label.text = "Cup: " + (" + ".join(names) if not names.is_empty() else "[color=#ffffff80]empty[/color]")
	for button: Button in ingredient_buttons.get_children():
		button.disabled = cup.size() >= CUP_CAPACITY
	for slot in _slots():
		slot.plate_button.disabled = slot.order == null or cup.is_empty()
	clear_button.disabled = cup.is_empty()

func _ingredient_text(ingredient: Ingredient) -> String:
	return "[color=#%s]%s[/color]" % [ingredient.color.lightened(0.35).to_html(false), ingredient.display_name]
