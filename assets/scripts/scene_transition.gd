extends CanvasLayer

@export var open_scale := 3.0
@export var scene_change_delay := 1.0

@export_group("Hide")
@export var hide_duration := 0.8
@export var hide_transition := Tween.TRANS_CUBIC
@export var hide_ease := Tween.EASE_IN

@export_group("Show")
@export var show_duration := 1.2
@export var show_transition := Tween.TRANS_SINE
@export var show_ease := Tween.EASE_IN_OUT

@onready var mask: ColorRect = %Mask


func change_scene(path: String) -> void:
	await hide_screen()
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	await show_screen(scene_change_delay)

func hide_screen() -> void:
	mask.visible = true
	await _tween_scale(open_scale, 0.0, hide_duration, hide_transition, hide_ease)

func show_screen(delay: float = 0.0) -> void:
	mask.visible = true
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	await _tween_scale(0.0, open_scale, show_duration, show_transition, show_ease)
	mask.visible = false

func _tween_scale(from: float, to: float, duration: float, transition: Tween.TransitionType, ease: Tween.EaseType) -> void:
	var tween := create_tween().set_trans(transition).set_ease(ease)
	tween.tween_method(_set_mask_scale, from, to, duration)
	await tween.finished

func _set_mask_scale(value: float) -> void:
	mask.material.set_shader_parameter("mask_scale", value)
