extends Node
@onready var cat_cue: AudioStreamPlayer = %CatCue

func play(sound: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sound
	player.bus = "SFX"
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	player.finished.connect(player.queue_free)
