class_name StoryEvents
extends Node

signal order_served(correct: bool)
@export var special_customer: Customer
@export var tutorial_coffee: Recipe
@export var tutorial_hot_chocolate: Recipe

@onready var cafe: Cafe = get_parent() as Cafe
@onready var slot: CustomerSlot = %SpecialCustomerSlot1

func tutorial() -> void:
	# setup
	var correct := false
	cafe.customer_slots.visible = false
	cafe.menu.recipes.clear()
	var coffee := tutorial_coffee.create_runtime_copy()
	cafe.menu.recipes.append(coffee)
	cafe.update_menu()
	slot.stay_after_serving = true
	slot.order_timer_enabled = false
	slot.seat(special_customer, coffee)
	SFXManager.play(special_customer.enters_sound)
	slot.can_serve = false
	cafe.update_controls()
	
	# intro stuff
	slot.say("intro_dialogue")
	await DialogueManager.dialogue_ended
	
	# order black coffee
	slot.say("order_tutorial_black_coffee")
	slot.can_serve = true
	cafe.update_controls()
	while not correct:
		correct = await order_served
	slot.can_serve = false
	cafe.update_controls()
	await DialogueManager.dialogue_ended
	
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
	slot.say("order_tutorial_hot_chocolate")
	slot.can_serve = true
	cafe.update_controls()
	correct = false
	while not correct:
		correct = await order_served
		
	# wrap up tutorial here
	await cafe.transition_shifts(cafe.finish_tutorial)
	cafe.recipe_swap_timer.start()
	cafe.seat_next_customer()
	cafe.arrival_timer.start()

func good_ending() -> void:
	print("WON!")

func bad_ending() -> void:
	print("Lost :(")
