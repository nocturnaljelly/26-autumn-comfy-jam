class_name CustomerSlot
extends Control

signal customer_arrived(customer: Customer)
signal customer_left(customer: Customer)

@export var fade_duration := 0.8
@export var customer_dialogue: DialogueResource
@export var happy_particles: PackedScene

@export_group("Motion")
@export var arrive_offset := 60.0
@export var arrive_duration := 0.7
@export var leave_offset := 40.0
@export var bob_pixels := 2.0
@export var bob_speed := 2.0

var customer: Customer
var order: Recipe
var order_number := 0
var expression := Customer.CustomerExpression.NEUTRAL
var _fade_tween: Tween
var active_balloon: Node
var balloon_visible := true
var _rise := 0.0
var _rise_tween: Tween
var _bob_time := randf() * TAU
var _applied_offset := Vector2.ZERO

@onready var customer_view: Control = %Customer
@onready var bubble: RichTextLabel = %Bubble
@onready var sprite: TextureRect = %Sprite
@onready var plate_button: Button = %PlateButton
@onready var dialogue_marker: DialogueMarker2D = %DialogueMarker2D


func _ready() -> void:
	customer_view.modulate.a = 0.0
	customer_view.sort_children.connect(func() -> void: _applied_offset = Vector2.ZERO)

func _process(delta: float) -> void:
	_bob_time += delta * bob_speed
	var bob := sin(_bob_time) * bob_pixels if customer else 0.0
	var offset := Vector2(0.0, _rise + bob)
	sprite.position += offset - _applied_offset
	_applied_offset = offset

func is_free() -> bool:
	return customer == null

func seat(new_customer: Customer, new_order: Recipe) -> void:
	customer = new_customer
	order = new_order
	expression = Customer.CustomerExpression.NEUTRAL
	sprite.texture = customer.get_random_sprite(expression)
	_tween_rise(arrive_offset, 0.0, arrive_duration, Tween.TRANS_BACK, Tween.EASE_OUT)
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

func get_payment_origin() -> Vector2:
	return sprite.get_global_rect().get_center()

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
	if correct:
		Juice.punch_scale(sprite, Vector2(-0.06, 0.1), 0.6, Vector2(0.5, 1.0))
		Juice.burst(happy_particles, self, get_payment_origin())
	else:
		Juice.shake_rotation(sprite, 5.0, 0.5, Vector2(0.5, 1.0))
	say("correct_order" if correct else "incorrect_order")
	leave()
	
func leave() -> void:
	if order == null:
		return
	order = null
	plate_button.disabled = true
	_tween_rise(_rise, leave_offset, fade_duration, Tween.TRANS_SINE, Tween.EASE_IN)
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

func _tween_rise(from: float, to: float, duration: float, transition: Tween.TransitionType, ease: Tween.EaseType) -> void:
	if _rise_tween:
		_rise_tween.kill()
	_rise = from
	_rise_tween = create_tween().set_trans(transition).set_ease(ease)
	_rise_tween.tween_property(self, "_rise", to, duration)

func _fade(alpha: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(customer_view, "modulate:a", alpha, fade_duration)
	await _fade_tween.finished
