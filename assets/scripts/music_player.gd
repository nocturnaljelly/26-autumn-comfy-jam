extends AudioStreamPlayer

@export var playlist: Array[AudioStream] = []

var current_track := 0
var playlist_enabled := false

func _ready() -> void:
	finished.connect(_play_next_track)

func play_music(music: AudioStream) -> void:
	playlist_enabled = false
	stream = music
	volume_db = -20.0
	play()
	fade_in()
	
func start_playlist() -> void:
	if playlist.is_empty():
		return
	playlist_enabled = true
	current_track = 0
	stream_paused = false
	volume_db = -30.0
	_play_next_track()
	fade_in()

func _play_next_track() -> void:
	if not playlist_enabled or playlist.is_empty():
		return
	stream = playlist[current_track]
	play()
	current_track = (current_track + 1) % playlist.size()
	
func fade_out() -> void:
	await create_tween().tween_property(self, "volume_db", -30.0, 2.0).finished
	stream_paused = true

func fade_in() -> void:
	stream_paused = false
	create_tween().tween_property(self, "volume_db", 0.0, 2.0)
