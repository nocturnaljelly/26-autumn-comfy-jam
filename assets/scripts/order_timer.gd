class_name OrderTimer
extends Control

@export var duration := 30.0

@export_group("Textures")
@export var normal_bar: Texture2D
@export var warning_bar: Texture2D
@export var critical_bar: Texture2D
@export var warning_threshold := 0.5
@export var critical_threshold := 0.2

@export_group("Urgency")
@export var urgency_start := 0.5
@export var max_pulse := 0.08
@export var min_pulse_speed := 3.0
@export var max_pulse_speed := 10.0
@export var max_wobble_degrees := 3.0
@onready var critical_sound: AudioStreamPlayer = %CriticalSound


@onready var timer: Timer = %Timer
@onready var progress_bar: TextureProgressBar = %TextureProgressBar
@onready var graphic: TextureRect = $TextureRect

signal timer_expired

var _phase := 0.0
var _base_scale := Vector2.ONE
var critical_sound_played := false

func _ready() -> void:
	timer.one_shot = true
	progress_bar.value = 100.0
	progress_bar.texture_progress = normal_bar
	timer.timeout.connect(_on_timeout)
	_base_scale = scale
	if graphic.texture:
		var pivot := graphic.position + graphic.texture.get_size() * Vector2(0.5, 1.0)
		position -= (pivot - pivot_offset) * (Vector2.ONE - _base_scale)
		pivot_offset = pivot

func _process(delta: float) -> void:
	if timer.is_stopped():
		return
	var progress := timer.time_left / duration
	progress_bar.value = progress * 100.0
	if progress <= critical_threshold and not critical_sound_played:
		critical_sound_played = true
		critical_sound.play()
		progress_bar.texture_progress = critical_bar
	elif progress <= warning_threshold:
		progress_bar.texture_progress = warning_bar
	else:
		progress_bar.texture_progress = normal_bar
	_animate(delta, progress)

func start() -> void:
	critical_sound_played = false
	progress_bar.value = 100.0
	progress_bar.texture_progress = normal_bar
	_phase = 0.0
	_reset_motion()
	timer.start(duration)

func stop() -> void:
	timer.stop()
	critical_sound.stop()
	_reset_motion()

func _animate(delta: float, progress: float) -> void:
	var intensity := clampf(inverse_lerp(urgency_start, 0.0, progress), 0.0, 1.0)
	intensity *= intensity
	_phase += delta * lerpf(min_pulse_speed, max_pulse_speed, intensity)
	scale = _base_scale * (1.0 + max_pulse * intensity * (0.5 + 0.5 * sin(_phase)))
	rotation_degrees = max_wobble_degrees * intensity * sin(_phase * 0.5)

func _reset_motion() -> void:
	scale = _base_scale
	rotation_degrees = 0.0

func _on_timeout() -> void:
	progress_bar.value = 0.0
	progress_bar.texture_progress = null
	_reset_motion()
	timer_expired.emit()
