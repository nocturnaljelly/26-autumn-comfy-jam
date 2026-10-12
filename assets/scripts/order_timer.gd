class_name OrderTimer
extends Control
@export var duration := 30

@export_group("Textures")
@export var normal_bar: Texture2D
@export var warning_bar: Texture2D
@export var critical_bar: Texture2D

@onready var timer: Timer = %Timer
@onready var progress_bar: TextureProgressBar = %TextureProgressBar

signal timer_expired

func _ready() -> void:
	timer.one_shot = true
	progress_bar.value = 0.0
	timer.timeout.connect(_on_timeout)
	
func _process(_delta: float) -> void:
	if timer.is_stopped():
		return
	var progress := timer.time_left / duration
	progress_bar.value = progress * 100.0
	if progress <= 0.2:
		progress_bar.texture_progress = critical_bar
	elif progress <= 0.5:
		progress_bar.texture_progress = warning_bar
	else:
		progress_bar.texture_progress = normal_bar

func start() -> void:
	progress_bar.value = 100.0
	progress_bar.texture_progress = normal_bar
	timer.start(duration)

func stop() -> void:
	timer.stop()

func _on_timeout() -> void:
	progress_bar.value = 0.0
	progress_bar.texture_progress = null
	timer_expired.emit()
