class_name CustomerSlot
extends VBoxContainer

signal customer_arrived(customer: Customer)
signal customer_left(customer: Customer)

@export var fade_duration := 0.8

var customer: Customer
var order: Recipe
var _fade_tween: Tween

@onready var customer_view: Control = %Customer
@onready var bubble: RichTextLabel = %Bubble
@onready var sprite: TextureRect = %Sprite
@onready var plate_button: Button = %PlateButton


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

func say(text: String) -> void:
	bubble.text = text

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
