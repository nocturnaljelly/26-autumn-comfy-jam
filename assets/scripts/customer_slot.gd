class_name CustomerSlot
extends Control

signal customer_arrived(customer: Customer)
signal customer_left(customer: Customer)

@export var fade_duration := 0.8
@export var customer_dialogue: DialogueResource

var customer: Customer
var order: Recipe
var order_number := 0
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
	sprite.texture = customer.sprite
	_fade(1.0)
	customer_arrived.emit(customer)

func say(cue: String) -> void:
	if is_instance_valid(active_balloon):
		active_balloon.queue_free()
		
	active_balloon = DialogueManager.show_dialogue_balloon(customer_dialogue, cue, [self])
	
	await get_tree().process_frame
	if is_instance_valid(active_balloon):
		active_balloon.visible = balloon_visible

func set_balloon_visible(value: bool) -> void:
	balloon_visible = value
	if is_instance_valid(active_balloon):
		active_balloon.visible = value

func leave() -> void:
	if order == null:
		return
	order = null
	plate_button.disabled = true
	await _fade(0.0)
	var leaving := customer
	customer = null
	bubble.text = ""
	customer_left.emit(leaving)

func _fade(alpha: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(customer_view, "modulate:a", alpha, fade_duration)
	await _fade_tween.finished
