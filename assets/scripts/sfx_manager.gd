extends Node

func play(sound: AudioStream, volume_db: float = 0.0) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sound
	player.bus = "SFX"
	player.volume_db = volume_db
	player.play()
	player.finished.connect(player.queue_free)
