class_name CoinTarget
extends Control

signal coin_received(value: int)

@export var visual: Control
@export var amount_label: Label
@export var pivot := Vector2(0.5, 0.5)

@export_group("Punch")
@export var punch_scale := 0.3
@export var punch_degrees := 12.0
@export var punch_duration := 0.5

var amount := 0

var _punch_tween: Tween
var _punch_side := 1.0


func _ready() -> void:
	visual.resized.connect(_center_pivot)
	_center_pivot()
	_update_label()

func get_catch_position() -> Vector2:
	return visual.get_global_transform_with_canvas() * (visual.size / 2.0)

func receive(value: int) -> void:
	amount += value
	_update_label()
	punch()
	coin_received.emit(value)

func punch() -> void:
	_punch_side = -_punch_side
	visual.scale = Vector2.ONE * (1.0 + punch_scale)
	visual.rotation_degrees = punch_degrees * _punch_side
	if _punch_tween:
		_punch_tween.kill()
	_punch_tween = create_tween().set_parallel().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_punch_tween.tween_property(visual, "scale", Vector2.ONE, punch_duration)
	_punch_tween.tween_property(visual, "rotation", 0.0, punch_duration)

func _update_label() -> void:
	if amount_label:
		amount_label.text = str(amount)

func _center_pivot() -> void:
	visual.pivot_offset = visual.size * pivot
