extends Node

func play(sound: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sound
	player.bus = "SFX"
	player.play()
	player.finished.connect(player.queue_free)
