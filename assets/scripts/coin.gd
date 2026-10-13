class_name Coin
extends Node2D
## A coin drawn in the same palette as the painted coins in the stall art.

const OUTLINE_COLOR := Color("5e3541")
const SHADE_COLOR := Color("d67654")
const FACE_COLOR := Color("ffb379")
const BACK_COLOR := Color("f5a570")
const SHINE_COLOR := Color("ffe6a9")

@export var radius := 12.0:
	set(value):
		radius = value
		queue_redraw()
## Full turns per second around the vertical axis.
@export var spin_speed := 0.0

var spin := 0.0:
	set(value):
		spin = value
		queue_redraw()


func _process(delta: float) -> void:
	if not is_zero_approx(spin_speed):
		spin += delta * spin_speed * TAU

func _draw() -> void:
	var turn := cos(spin)
	var outline := maxf(1.5, radius * 0.14)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(maxf(absf(turn), 0.12), 1.0))
	draw_circle(Vector2.ZERO, radius, OUTLINE_COLOR, true, -1.0, true)
	draw_circle(Vector2.ZERO, radius - outline, SHADE_COLOR, true, -1.0, true)
	draw_circle(Vector2(0, -radius * 0.1), (radius - outline) * 0.84, FACE_COLOR if turn >= 0.0 else BACK_COLOR, true, -1.0, true)
	draw_circle(Vector2(-radius * 0.28 * signf(turn), -radius * 0.32), radius * 0.2, SHINE_COLOR, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
