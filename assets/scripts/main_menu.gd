extends Control

@export_file("*.tscn") var game_scene: String

@onready var play_button: Button = %PlayButton
@export var menu_music: AudioStream
@export var ui_select: AudioStream

func _ready() -> void:
	MusicPlayer.play_music(menu_music)
	play_button.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	SFXManager.play(ui_select, 5.0)
	SceneTransition.change_scene(game_scene)
