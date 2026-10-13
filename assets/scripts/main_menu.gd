extends Control

@export_file("*.tscn") var game_scene: String

@onready var play_button: Button = %PlayButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	SceneTransition.change_scene(game_scene)
