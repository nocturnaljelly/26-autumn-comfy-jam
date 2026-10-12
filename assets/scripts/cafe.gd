extends Control

const CUP_CAPACITY := 4
const HIGHLIGHT_COLOR := "#ffd27a"
enum View { CUSTOMERS, PREP }

@export var recipe_book: RecipeBook
@export var customers: Array[Customer] = []
@export var ambience: AudioStream
	
var menu: RecipeBook
var cup: Array[Ingredient] = []
var current_view := View.CUSTOMERS
var facing_menu := false
var customers_in_sight := true
var recipe_swap_in_progress := false
var recipe_swap_pending := false
var completed_recipes: Array[StringName] = []

@onready var counter_view: Control = %CounterView
@onready var customer_slots: Container = %CustomerSlots
@onready var arrival_timer: Timer = %ArrivalTimer
@onready var cup_view: CupView = %CupView
@onready var cup_label: RichTextLabel = %CupLabel
@onready var ingredient_bins: Control = %IngredientBins
@onready var clear_button: Button = %ClearButton
@onready var customer_view: Control = %CustomerView
@onready var to_prep_button: Button = $CounterView/CustomerView/ToPrepButton
@onready var prep_view: Control = %PrepView
@onready var to_customers_button: Button = $CounterView/PrepView/ToCustomersButton
@onready var menu_view: Control = %MenuView
@onready var menu_label: RichTextLabel = %MenuLabel
@onready var recipes_button: Button = %RecipesButton
@onready var back_button: Button = %BackButton
@onready var paw_graphic: ColorRect = %PawGraphic
@onready var recipe_swap_timer: Timer = %RecipeSwapTimer
@onready var swap_bubble: TextureRect = %SwapBubble


func _ready() -> void:
	SFXManager.play(ambience, -30.0)
	menu = recipe_book.create_runtime_copy()
	var bins := _bins()
	if menu.ingredients.size() > bins.size():
		push_warning("%d ingredients but only %d ingredient bins" % [menu.ingredients.size(), bins.size()])
	for i in mini(menu.ingredients.size(), bins.size()):
		bins[i].ingredient = menu.ingredients[i]
	cup_view.ingredient_dropped.connect(_add_ingredient)
	for slot in _slots():
		slot.plate_button.pressed.connect(_serve.bind(slot))
	clear_button.pressed.connect(_clear_cup)
	recipes_button.pressed.connect(_turn)
	back_button.pressed.connect(_turn)
	arrival_timer.timeout.connect(_seat_next_customer)
	to_prep_button.pressed.connect(_show_view.bind(View.PREP))
	to_customers_button.pressed.connect(_show_view.bind(View.CUSTOMERS))
	menu_view.visible = false
	recipe_swap_timer.wait_time = 8
	recipe_swap_timer.one_shot = true
	recipe_swap_timer.timeout.connect(_request_recipe_swap)
	recipe_swap_timer.start()
	_update_menu()
	_show_view(View.CUSTOMERS)
	_seat_next_customer()
	_update_controls()

func _turn() -> void:
	facing_menu = not facing_menu
	counter_view.visible = not facing_menu
	menu_view.visible = facing_menu
	_update_balloon_visibility()
	_check_pending_recipe_swap()
	
func _slots() -> Array[CustomerSlot]:
	var slots: Array[CustomerSlot] = []
	slots.assign(customer_slots.get_children())
	return slots

func _bins() -> Array[IngredientBin]:
	var bins: Array[IngredientBin] = []
	bins.assign(ingredient_bins.get_children())
	return bins

func _seat_next_customer() -> void:
	var free_slots := _slots().filter(func(slot: CustomerSlot) -> bool: return slot.is_free())
	if free_slots.is_empty():
		return
	var free_slot: CustomerSlot = free_slots.pick_random()
	var customer := _pick_customer()
	free_slot.seat(customer, menu.get_random_recipe())
	SFXManager.play(customer.enters_sound)
	_update_order_text(free_slot)
	_update_controls()

func _pick_customer() -> Customer:
	var seated := _slots().map(func(slot: CustomerSlot) -> Customer: return slot.customer)
	var options := customers.filter(func(customer: Customer) -> bool: return not seated.has(customer))
	return options.pick_random() if not options.is_empty() else customers.pick_random()

func _serve(slot: CustomerSlot) -> void:
	var correct := completed_recipes.has(slot.order.id)
	var sound: AudioStream = slot.customer.satisfied_sound if correct else slot.customer.dissatisfied_sound
	SFXManager.play(sound)
	slot.set_expression(Customer.CustomerExpression.SATISFIED if correct else Customer.CustomerExpression.DISSATISFIED)
	slot.say("correct_order" if correct else "incorrect_order")
	slot.leave()
	_clear_cup()

func _add_ingredient(ingredient: Ingredient) -> void:
	if cup.size() < CUP_CAPACITY:
		cup.append(ingredient)
		_update_controls()
		completed_recipes.clear()
		for recipe in menu.recipes:
			if recipe.matches(cup):
				completed_recipes.append(recipe.id)
		_update_controls()
		
func _clear_cup() -> void:
	cup.clear()
	completed_recipes.clear()
	_update_controls()

func _show_view(view: View) -> void:
	current_view = view
	customer_view.visible = view == View.CUSTOMERS
	prep_view.visible = view == View.PREP
	_update_balloon_visibility()
	_check_pending_recipe_swap()
	
func _update_order_text(slot: CustomerSlot) -> void:
	slot.order_number = menu.get_number(slot.order)
	slot.set_expression(Customer.CustomerExpression.NEUTRAL)
	slot.say("order")

func _update_balloon_visibility() -> void:
	var in_sight := current_view == View.CUSTOMERS and not facing_menu
	if customers_in_sight and not in_sight:
		_change_customer_sprites()
	customers_in_sight = in_sight
	for slot in _slots():
		slot.set_balloon_visible(in_sight)

func _change_customer_sprites() -> void:
	for slot in _slots():
		if slot.order and randf() < slot.customer.sprite_change_chance:
			slot.change_sprite()

func _request_recipe_swap() -> void:
	recipe_swap_pending = true
	_check_pending_recipe_swap()

func _check_pending_recipe_swap() -> void:
	if not recipe_swap_pending or recipe_swap_in_progress or facing_menu:
		return
	recipe_swap_pending = false
	recipe_swap_in_progress = true
	if current_view == View.PREP:
		recipes_button.disabled = true
		_animate_recipe_swap()
	else:
		_animate_swap_bubble()

# hash out the motion
func _animate_recipe_swap() -> void:
	var button_start := recipes_button.global_position.x
	var paw_end := paw_graphic.global_position.x
	var paw_start := -paw_graphic.size.x
	paw_graphic.global_position.x = paw_start
	paw_graphic.visible = true
	
	var tween := create_tween()
	tween.tween_property(paw_graphic, "global_position:x", paw_end, 0.2)
	tween.tween_property(paw_graphic, "global_position:x", paw_start, 0.3)
	tween.parallel().tween_property(recipes_button, "global_position:x", -recipes_button.size.x - 10.0, 0.3)
	await tween.finished
	
	_swap_recipes()
	await get_tree().create_timer(0.3).timeout
	
	tween = create_tween()
	tween.tween_property(paw_graphic, "global_position:x", paw_end, 0.5)
	tween.parallel().tween_property(recipes_button, "global_position:x", button_start, 0.5)
	tween.tween_property(paw_graphic, "global_position:x", paw_start, 0.2)
	await tween.finished
	
	paw_graphic.visible = false
	paw_graphic.global_position.x = paw_end
	_finish_recipe_swap()

func _animate_swap_bubble() -> void:
	SFXManager.cat_cue.play()
	menu.reset_from(recipe_book)
	swap_bubble.pivot_offset = swap_bubble.size / 2.0
	swap_bubble.scale = Vector2.ZERO
	swap_bubble.visible = true
	var tween := create_tween()
	tween.tween_property(swap_bubble, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_EXPO)
	for i in 4:
		tween.tween_property(swap_bubble, "rotation_degrees", -5.0, 0.1)
		tween.tween_property(swap_bubble, "rotation_degrees", 5.0, 0.1)
	tween.tween_property(swap_bubble, "rotation_degrees", 0.0, 0.05)
	tween.tween_property(swap_bubble, "scale", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	
	_finish_recipe_swap()

func _swap_recipes() -> void:
	menu.reset_from(recipe_book)
	menu.change_random_recipe(CUP_CAPACITY)
	_update_menu()

func _finish_recipe_swap() -> void:
	recipe_swap_in_progress = false
	recipes_button.disabled = false
	swap_bubble.visible = false
	recipe_swap_timer.start()

func _update_menu() -> void:
	var lines: PackedStringArray = []
	for recipe in menu.recipes:
		var names: PackedStringArray = []
		for ingredient in recipe.ingredients:
			names.append(_ingredient_image(ingredient))
		lines.append("[color=%s]%d.[/color] %s = [wave amp=25 freq=3]%s[/wave]" % [HIGHLIGHT_COLOR, menu.get_number(recipe), " + ".join(names), recipe.display_name])
	menu_label.text = "\n".join(lines)

func _update_controls() -> void:
	var names: PackedStringArray = []
	for ingredient in cup:
		names.append(_ingredient_image(ingredient, true))
	if not names.is_empty():
		names[names.size() - 1] = "%s" % names[names.size() - 1]
	cup_label.text = "Cup: " + (" + ".join(names) if not names.is_empty() else "[color=#ffffff80]empty[/color]")
	for bin in _bins():
		bin.disabled = cup.size() >= CUP_CAPACITY
	cup_view.is_full = cup.size() >= CUP_CAPACITY
	for slot in _slots():
		slot.plate_button.disabled = slot.order == null or cup.is_empty()
	clear_button.disabled = cup.is_empty()

func _ingredient_image(ingredient: Ingredient, in_cup: bool = false) -> String:
	var texture := ingredient.grab_cursor if in_cup else ingredient.food_graphic
	return "[img]%s[/img]" % texture.resource_path
	
func _ingredient_text(ingredient: Ingredient) -> String:
	return "[color=#%s]%s[/color]" % [ingredient.color.lightened(0.35).to_html(false), ingredient.display_name]
