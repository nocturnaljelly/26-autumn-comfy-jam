extends Node

@export var confused_sounds: Array[AudioStream] = []

func play(sound: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0, pan_right: bool = false) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sound
	player.bus = "SFX_RIGHT" if pan_right else "SFX"
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	player.finished.connect(player.queue_free)
