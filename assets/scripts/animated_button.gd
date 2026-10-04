class_name AnimatedButton
extends Button

@export_group("Hover")
@export var hover_scale := 1.08
@export var press_scale := 0.92
@export var hover_duration := 0.18
@export var press_duration := 0.08

@export_group("Idle")
@export var idle_bob_pixels := 3.0
@export var idle_tilt_degrees := 2.0
@export var idle_speed := 2.0

var _scale := 1.0
var _target_scale := 1.0
var _tween: Tween
var _idle_time := randf() * TAU
var _idle_offset := Vector2.ZERO


func _ready() -> void:
	resized.connect(_center_pivot)
	draw.connect(_animate_to_state)
	var container := get_parent() as Container
	if container:
		container.sort_children.connect(_on_parent_sorted)
	_center_pivot()

func _process(delta: float) -> void:
	_idle_time += delta * idle_speed
	var offset := Vector2(0, sin(_idle_time) * idle_bob_pixels)
	position += offset - _idle_offset
	_idle_offset = offset
	rotation = deg_to_rad(sin(_idle_time * 0.7 + 1.3) * idle_tilt_degrees)
	scale = Vector2.ONE * _scale

func _on_parent_sorted() -> void:
	if is_visible_in_tree():
		_idle_offset = Vector2.ZERO

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
	_tween.tween_property(self, "_scale", target, duration)
