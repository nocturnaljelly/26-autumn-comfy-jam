extends Control

const CUP_CAPACITY := 4
const HIGHLIGHT_COLOR := "#ffd27a"
enum View { CUSTOMERS, PREP }

@export var recipe_book: RecipeBook
@export var customers: Array[Customer] = []
@export var progressions: Array[GameProgression] = []
@export var ambience: AudioStream
@export var correct_order_money := 10
@export var wrong_order_money := 2

@export_group("Juice")
@export var drop_particles: PackedScene
@export var recipe_particles: PackedScene
@export var wrong_order_shake := 3.0
@export var view_slide_duration := 0.35
@export var menu_drop_duration := 0.5

@export_group("Sounds")
@export var recipe_open_sound: AudioStream
@export var recipe_close_sound: AudioStream
@export var correct_order_sound: AudioStream
@export var transform_sound: AudioStream
@export var cat_cue_sound: AudioStream

var menu: RecipeBook
var cup: Array[Ingredient] = []
var current_view := View.CUSTOMERS
var facing_menu := false
var customers_in_sight := true
var recipe_swap_wait_time = 2.0
var recipe_swap_in_progress := false
var recipe_swap_pending := false
var completed_recipes: Array[StringName] = []
var customers_arrived := 0
var current_progression := 0
var progression_recipe_book: RecipeBook
var money := 0
var _slide_tween: Tween
var _menu_tween: Tween

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

@onready var lighting: Control = %Lighting
@onready var modulation: CanvasModulate = %Modulation
@onready var coin_spawner: CoinSpawner = %CoinSpawner

func _ready() -> void:
	SFXManager.play(ambience, -30.0)
	MusicPlayer.start_playlist()
	menu = recipe_book.create_runtime_copy()
	var bins := _bins()
	if menu.ingredients.size() > bins.size():
		push_warning("%d ingredients but only %d ingredient bins" % [menu.ingredients.size(), bins.size()])
	for i in mini(menu.ingredients.size(), bins.size()):
		bins[i].ingredient = menu.ingredients[i]
	cup_view.ingredient_dropped.connect(_add_ingredient)
	for slot in _slots():
		slot.plate_button.pressed.connect(_serve.bind(slot))
		slot.customer_left.connect(_on_customer_left)
	clear_button.pressed.connect(_clear_cup)
	recipes_button.pressed.connect(_turn)
	back_button.pressed.connect(_turn)
	arrival_timer.timeout.connect(_seat_next_customer)
	to_prep_button.pressed.connect(_show_view.bind(View.PREP))
	to_customers_button.pressed.connect(_show_view.bind(View.CUSTOMERS))
	menu_view.visible = false
	recipe_swap_timer.wait_time = recipe_swap_wait_time
	recipe_swap_timer.one_shot = true
	recipe_swap_timer.timeout.connect(_request_recipe_swap)
	recipe_swap_timer.start()
	if not progressions.is_empty():
		_apply_progression()
	else:
		progression_recipe_book = recipe_book
		_update_menu()
		
	_show_view(View.CUSTOMERS, false)
	_seat_next_customer()
	_update_controls()

func _turn() -> void:
	facing_menu = not facing_menu
	SFXManager.play(recipe_open_sound if facing_menu else recipe_close_sound)
	_update_balloon_visibility()
	if _menu_tween:
		_menu_tween.kill()
	counter_view.visible = true
	menu_view.visible = true
	_menu_tween = create_tween()
	if facing_menu:
		menu_view.position.y = -menu_view.size.y
		_menu_tween.tween_property(menu_view, "position:y", 0.0, menu_drop_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_menu_tween.tween_property(menu_view, "position:y", -menu_view.size.y, menu_drop_duration * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await _menu_tween.finished
	counter_view.visible = not facing_menu
	menu_view.visible = facing_menu
	menu_view.position.y = 0.0
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
	if _shift_finished():
		return
	if progression_in_progress:
		return
	var free_slots := _slots().filter(func(slot: CustomerSlot) -> bool: return slot.is_free())
	if free_slots.is_empty():
		return
	var free_slot: CustomerSlot = free_slots.pick_random()
	var customer := _pick_customer()
	free_slot.seat(customer, menu.get_random_recipe())
	free_slot.order_duration = progressions[current_progression].order_duration
	customers_arrived += 1
	SFXManager.play(customer.enters_sound)
	_update_order_text(free_slot)
	_update_controls()

func _pick_customer() -> Customer:
	var seated := _slots().map(func(slot: CustomerSlot) -> Customer: return slot.customer)
	var options := customers.filter(func(customer: Customer) -> bool: return not seated.has(customer))
	return options.pick_random() if not options.is_empty() else customers.pick_random()

func _serve(slot: CustomerSlot) -> void:
	var correct := completed_recipes.has(slot.order.id)
	var amount := correct_order_money if correct else wrong_order_money
	money += amount
	coin_spawner.spawn(amount, slot.get_payment_origin())
	if correct:
		SFXManager.play(correct_order_sound)
	slot.react(correct)
	if not correct:
		Juice.shake_position(self, wrong_order_shake)
	_clear_cup()

func _on_customer_left(_customer: Customer) -> void:
	_advance_progression()
func _add_ingredient(ingredient: Ingredient) -> void:
	if cup.size() < CUP_CAPACITY:
		cup.append(ingredient)
		_update_controls()
		var had_recipe := not completed_recipes.is_empty()
		completed_recipes.clear()
		for recipe in menu.recipes:
			if recipe.matches(cup):
				completed_recipes.append(recipe.id)
		_update_controls()
		var puff := Juice.burst(drop_particles, cup_view, get_global_mouse_position())
		if puff is CPUParticles2D:
			puff.color = ingredient.color
		if not completed_recipes.is_empty() and not had_recipe:
			Juice.punch_scale(cup_view, Vector2(0.06, 0.06), 0.6)
			Juice.shake_rotation(cup_view, 2.0, 0.5)
			Juice.burst(recipe_particles, cup_view, cup_label.get_global_rect().get_center())
		else:
			Juice.punch_scale(cup_label, Vector2(0.12, -0.1))

func _clear_cup() -> void:
	if not cup.is_empty():
		Juice.punch_scale(cup_label, Vector2(-0.3, -0.3), 0.5)
	cup.clear()
	completed_recipes.clear()
	_update_controls()

func _show_view(view: View, animate := true) -> void:
	if recipe_swap_in_progress:
		return
	var previous := current_view
	current_view = view
	var incoming := customer_view if view == View.CUSTOMERS else prep_view
	var outgoing := prep_view if view == View.CUSTOMERS else customer_view
	if _slide_tween:
		_slide_tween.kill()
	customer_view.position.x = 0.0
	prep_view.position.x = 0.0
	_update_balloon_visibility()
	if animate and previous != view:
		var width := counter_view.size.x
		var direction := 1.0 if view == View.CUSTOMERS else -1.0
		incoming.visible = true
		incoming.position.x = width * direction
		_slide_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_slide_tween.tween_property(incoming, "position:x", 0.0, view_slide_duration)
		_slide_tween.tween_property(outgoing, "position:x", -width * direction, view_slide_duration)
		await _slide_tween.finished
		outgoing.position.x = 0.0
	customer_view.visible = view == View.CUSTOMERS
	prep_view.visible = view == View.PREP
	
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
			SFXManager.play(transform_sound)

func _request_recipe_swap() -> void:
	if _stop_recipe_swaps():
		return
	recipe_swap_pending = true
	_check_pending_recipe_swap()

func _check_pending_recipe_swap() -> void:
	if _stop_recipe_swaps():
		return
	if not recipe_swap_pending or recipe_swap_in_progress or facing_menu:
		return
	if (_slide_tween and _slide_tween.is_running()) or (_menu_tween and _menu_tween.is_running()):
		return
	recipe_swap_pending = false
	recipe_swap_in_progress = true
	to_prep_button.modulate.a = 0.5
	to_customers_button.modulate.a = 0.5
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
	
	var clipboard: Control = recipes_button.get_node("Clipboard")
	var tween := create_tween()
	tween.tween_property(paw_graphic, "global_position:x", paw_end, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: Juice.shake_rotation(clipboard, 6.0, 0.3))
	tween.tween_interval(0.1)
	tween.tween_property(paw_graphic, "global_position:x", paw_start, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(recipes_button, "global_position:x", -recipes_button.size.x - 10.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	
	_swap_recipes()
	await get_tree().create_timer(0.3).timeout
	
	tween = create_tween()
	tween.tween_property(paw_graphic, "global_position:x", paw_end, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(recipes_button, "global_position:x", button_start, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: Juice.punch_scale(clipboard, Vector2(0.1, 0.1)))
	tween.tween_property(paw_graphic, "global_position:x", paw_start, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	
	paw_graphic.visible = false
	paw_graphic.global_position.x = paw_end
	_finish_recipe_swap()

func _animate_swap_bubble() -> void:
	SFXManager.play(cat_cue_sound)
	_swap_recipes()
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
	menu.reset_from(progression_recipe_book)
	menu.change_random_recipe(CUP_CAPACITY)
	_update_menu()

func _finish_recipe_swap() -> void:
	recipe_swap_in_progress = false
	recipes_button.disabled = false
	swap_bubble.visible = false
	recipe_swap_timer.start()
	to_prep_button.modulate.a = 1.0
	to_customers_button.modulate.a = 1.0

func _stop_recipe_swaps() -> bool:
	if not _shift_finished():
		return false
	for slot in _slots():
		if slot.order and not slot.is_order_almost_expired():
			return false
	return true

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

func _shift_finished() -> bool:
	return current_progression + 1 < progressions.size() and customers_arrived >= progressions[current_progression + 1].customers_required

func _apply_progression() -> void:
	var progression := progressions[current_progression]
	progression_recipe_book = recipe_book.duplicate()
	progression_recipe_book.recipes = progression.recipes.duplicate()
	menu = progression_recipe_book.create_runtime_copy()
	_update_menu()
	modulation.visible = progression.night_enabled
	lighting.visible = progression.night_enabled
	
var progression_in_progress := false
func _advance_progression():
	if progression_in_progress or not _shift_finished():
		return
	for slot in _slots():
		if not slot.is_free():
			return
	progression_in_progress = true
	while recipe_swap_in_progress:
		await get_tree().process_frame
	await MusicPlayer.fade_out()
	await SceneTransition.hide_screen()
	current_progression += 1
	_apply_progression()
	await SceneTransition.show_screen(2.0)
	MusicPlayer.fade_in()
	recipe_swap_pending = false
	recipe_swap_timer.start()
	progression_in_progress = false
