class_name StoryEvents
extends Node

signal order_served(correct: bool)
signal order_attempt_finished(correct: bool)
@export var special_customer: Customer
@export var tutorial_coffee: Recipe
@export var tutorial_hot_chocolate: Recipe
@export var tutorial_timer_duration := 10.0

@onready var cafe: Cafe = get_parent() as Cafe
@onready var slot: CustomerSlot = %SpecialCustomerSlot1

@export var good_ending_sound: AudioStream
@export var bad_ending_sound: AudioStream

func tutorial() -> void:
	# setup
	slot.order_expired.connect(func(): order_attempt_finished.emit(false))
	order_served.connect(func(correct: bool): order_attempt_finished.emit(correct))
	cafe.customer_slots.visible = false
	cafe.menu.recipes.clear()
	var coffee := tutorial_coffee.create_runtime_copy()
	cafe.menu.recipes.append(coffee)
	cafe.update_menu()
	slot.stay_after_serving = true
	slot.order_duration = tutorial_timer_duration
	slot.seat(special_customer, coffee)
	SFXManager.play(special_customer.enters_sound)
	slot.can_serve = false
	cafe.update_controls()
	
	# intro stuff
	slot.say("intro_dialogue")
	await DialogueManager.dialogue_ended
	
	# order black coffee
	await _wait_for_order("order_tutorial_black_coffee")
	
	# unlock the hot chocolate
	var hot_chocolate := tutorial_hot_chocolate.create_runtime_copy()
	cafe.menu.recipes.append(hot_chocolate)
	cafe.update_menu()
	
	# warn the player about Moka and swap the recipe
	slot.set_expression(Customer.CustomerExpression.NEUTRAL)
	slot.say("tutorial_cat_warning_1")
	await DialogueManager.dialogue_ended
	
	# swap recipes
	cafe.recipe_swap_in_progress = true
	await cafe.animate_swap_bubble(hot_chocolate.id)
	
	
	# react to swap
	slot.say("tutorial_cat_warning_2")
	await DialogueManager.dialogue_ended
	
	# order hot chocolate
	slot.order = hot_chocolate
	slot.set_expression(Customer.CustomerExpression.NEUTRAL)
	await _wait_for_order("order_tutorial_hot_chocolate")
	
	# wrap up tutorial here
	slot.say("end_tutorial")
	await DialogueManager.dialogue_ended
	await cafe.transition_shifts(cafe.finish_tutorial, false)
	cafe.recipe_swap_timer.start()
	cafe.seat_next_customer()
	cafe.arrival_timer.start()

func _wait_for_order(cue: String) -> void:
	while true:
		slot.say(cue)
		slot.can_serve = true
		cafe.update_controls()
		var correct: bool = await order_attempt_finished
		slot.can_serve = false
		cafe.update_controls()
		await DialogueManager.dialogue_ended
		slot.set_expression(Customer.CustomerExpression.NEUTRAL)
		if correct:
			return

func _start_ending() -> void:
	await MusicPlayer.fade_out()
	await SceneTransition.hide_screen()
	cafe.customer_slots.visible = false
	slot.get_parent().visible = true
	slot.seat(special_customer, null)
	slot.plate_button.hide()
	await SceneTransition.show_screen(5.0)

func good_ending() -> void:
	await _start_ending()
	slot.set_expression(Customer.CustomerExpression.SATISFIED)
	slot.say("good_ending")
	await DialogueManager.dialogue_ended
	SFXManager.play(good_ending_sound)

func bad_ending() -> void:
	await _start_ending()
	slot.set_expression(Customer.CustomerExpression.DISSATISFIED)
	slot.say("bad_ending_1")
	await DialogueManager.dialogue_ended
	cafe.coin_spawner.spawn(50, slot.get_payment_origin())
	slot.say("bad_ending_2")
	await DialogueManager.dialogue_ended
	SFXManager.play(bad_ending_sound)
