class_name CustomerSlot
extends Control

signal customer_arrived(customer: Customer)
signal customer_left(customer: Customer)

@export var fade_duration := 0.8
@export var customer_dialogue: DialogueResource

var customer: Customer
var order: Recipe
var order_number := 0
var expression := Customer.CustomerExpression.NEUTRAL
var _fade_tween: Tween
var active_balloon: Node
var balloon_visible := true

@onready var customer_view: Control = %Customer
@onready var bubble: RichTextLabel = %Bubble
@onready var sprite: TextureRect = %Sprite
@onready var plate_button: Button = %PlateButton
@onready var dialogue_marker: DialogueMarker2D = %DialogueMarker2D


func _ready() -> void:
	customer_view.modulate.a = 0.0

func is_free() -> bool:
	return customer == null

func seat(new_customer: Customer, new_order: Recipe) -> void:
	customer = new_customer
	order = new_order
	expression = Customer.CustomerExpression.NEUTRAL
	sprite.texture = customer.get_random_sprite(expression)
	_fade(1.0)
	customer_arrived.emit(customer)

func change_sprite() -> void:
	sprite.texture = customer.get_random_sprite(expression, sprite.texture)

func set_expression(new_expression: Customer.CustomerExpression) -> void:
	expression = new_expression
	sprite.texture = customer.get_expression_sprite(sprite.texture, expression)

func say(cue: String) -> void:
	if is_instance_valid(active_balloon):
		active_balloon.queue_free()
	active_balloon = DialogueManager.show_dialogue_balloon(customer_dialogue, cue, [self])
	if is_instance_valid(active_balloon):
		active_balloon.visible = balloon_visible
		if cue == "order":
			var order_timer: OrderTimer = active_balloon.get_node("Balloon/OrderTimer")
			if not order_timer.is_node_ready():
				await order_timer.ready
			order_timer.timer_expired.connect(_on_order_expired)
			order_timer.start()
		await active_balloon.open_animation()

func set_balloon_visible(value: bool) -> void:
	balloon_visible = value
	if is_instance_valid(active_balloon):
		active_balloon.visible = value

func react(correct: bool) -> void:
	if order == null:
		return
	var sound := customer.satisfied_sound if correct else customer.dissatisfied_sound
	SFXManager.play(sound)
	set_expression(Customer.CustomerExpression.SATISFIED if correct else Customer.CustomerExpression.DISSATISFIED)
	say("correct_order" if correct else "incorrect_order")
	leave()
	
func leave() -> void:
	if order == null:
		return
	order = null
	plate_button.disabled = true
	_fade(0.0)
	if is_instance_valid(active_balloon):
		await active_balloon.close_animation()
		active_balloon.queue_free()
		active_balloon = null
	if _fade_tween and _fade_tween.is_running():
		await _fade_tween.finished
	var leaving := customer
	customer = null
	bubble.text = ""
	customer_left.emit(leaving)

func _on_order_expired() -> void:
	if order == null:
		return
	react(false)

func _fade(alpha: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(customer_view, "modulate:a", alpha, fade_duration)
	await _fade_tween.finished
