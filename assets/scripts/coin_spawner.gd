class_name CoinSpawner
extends CanvasLayer

signal coin_arrived(value: int)

@export var coin_scene: PackedScene
@export var fly_target: CoinTarget

@export_group("Motion")
@export var spawn_interval := 0.06
@export var burst_distance := Vector2(50.0, 130.0)
@export var burst_duration := 0.35
@export var hang_time := 0.1
@export var flight_duration := 0.6
@export var arc_height := 140.0
@export var landing_scale := 0.7

@export_group("Sound")
@export var coin_sound: AudioStream
@export var coin_volume_db := 0.0
@export var pitch_step := 0.06
@export var max_pitch := 2.0
@export var combo_reset_time := 0.5

var _combo := 0
var _combo_timer := 0.0


func _process(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo = 0

func spawn(count: int, from: Vector2, value := 1) -> void:
	for i in count:
		_launch_coin(from, i * spawn_interval, value)

func _launch_coin(from: Vector2, delay: float, value: int) -> void:
	var coin: Node2D = coin_scene.instantiate()
	coin.position = from
	coin.scale = Vector2.ZERO
	add_child(coin)

	var burst := from + Vector2.from_angle(randf_range(-PI * 0.9, -PI * 0.1)) * randf_range(burst_distance.x, burst_distance.y)
	var bend := randf_range(-0.5, 0.5)
	var tween := coin.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(coin, "scale", Vector2.ONE, burst_duration * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(coin, "position", burst, burst_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hang_time * randf_range(0.5, 1.5))
	tween.tween_method(_fly.bind(coin, burst, bend), 0.0, 1.0, flight_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_arrive.bind(coin, value))

func _fly(t: float, coin: Node2D, start: Vector2, bend: float) -> void:
	var end := fly_target.get_catch_position() if fly_target else start + Vector2.UP * arc_height
	var control := (start + end) / 2.0 + Vector2(0.0, -arc_height) + (end - start).orthogonal() * bend * 0.3
	coin.position = start.lerp(control, t).lerp(control.lerp(end, t), t)
	coin.scale = Vector2.ONE * lerpf(1.0, landing_scale, t)

func _arrive(coin: Node2D, value: int) -> void:
	coin.queue_free()
	_play_coin_sound()
	if fly_target:
		fly_target.receive(value)
	coin_arrived.emit(value)

func _play_coin_sound() -> void:
	if coin_sound:
		SFXManager.play(coin_sound, coin_volume_db, minf(1.0 + _combo * pitch_step, max_pitch))
	_combo += 1
	_combo_timer = combo_reset_time
