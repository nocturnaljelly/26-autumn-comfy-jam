class_name AnimatedButton
extends Button

@export var hover_scale := 1.08
@export var press_scale := 0.92
@export var hover_duration := 0.18
@export var press_duration := 0.08

var _target_scale := 1.0
var _tween: Tween


func _ready() -> void:
	resized.connect(_center_pivot)
	draw.connect(_animate_to_state)
	_center_pivot()

func _center_pivot() -> void:
	pivot_offset = size / 2

func _animate_to_state() -> void:
	var target := 1.0
	var duration := hover_duration
	match get_draw_mode():
		DRAW_HOVER:
			target = hover_scale
		DRAW_PRESSED, DRAW_HOVER_PRESSED:
			target = press_scale
			duration = press_duration
	if is_equal_approx(target, _target_scale):
		return
	_target_scale = target
	z_index = 1 if target > 1.0 else 0
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE * target, duration)
