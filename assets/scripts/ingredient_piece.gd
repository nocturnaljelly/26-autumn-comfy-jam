class_name IngredientPiece
extends Control

const OUTLINE_DARKEN := 0.35
const OUTLINE_RATIO := 0.06
const SHADOW_COLOR := Color(0.31, 0.18, 0.12, 0.25)

@export var pop_duration := 0.0
@export var sway_degrees := 0.0
@export var show_shadow := false

var ingredient: Ingredient:
	set(value):
		ingredient = value
		queue_redraw()

var _last_position := Vector2.ZERO


func _ready() -> void:
	pivot_offset = size / 2
	_last_position = global_position
	if pop_duration > 0.0:
		scale = Vector2.ONE * 0.4
		create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(self, "scale", Vector2.ONE, pop_duration)

func _process(delta: float) -> void:
	if is_zero_approx(sway_degrees):
		return
	var velocity := (global_position - _last_position) / maxf(delta, 0.001)
	_last_position = global_position
	var target := deg_to_rad(clampf(velocity.x * 0.02, -sway_degrees, sway_degrees))
	rotation = lerp_angle(rotation, target, minf(delta * 10.0, 1.0))

func _draw() -> void:
	if not ingredient:
		return
	var piece_size := minf(size.x, size.y)
	if show_shadow:
		draw_set_transform(size / 2 + Vector2(0, piece_size * 0.45), 0.0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, piece_size * 0.36, SHADOW_COLOR)
	draw_piece(self, ingredient, size / 2, piece_size)

static func draw_piece(canvas: CanvasItem, piece_ingredient: Ingredient, center: Vector2, piece_size: float, angle := 0.0, tint := Color.WHITE) -> void:
	canvas.draw_set_transform(center, angle)
	if piece_ingredient.icon:
		var icon_size := piece_ingredient.icon.get_size()
		var fitted := icon_size * piece_size / maxf(icon_size.x, icon_size.y)
		canvas.draw_texture_rect(piece_ingredient.icon, Rect2(-fitted / 2, fitted), false, tint)
	else:
		var color := piece_ingredient.color * tint
		var square := Rect2(-Vector2.ONE * piece_size * 0.4, Vector2.ONE * piece_size * 0.8)
		canvas.draw_rect(square, color)
		canvas.draw_rect(square, color.darkened(OUTLINE_DARKEN), false, maxf(1.0, piece_size * OUTLINE_RATIO))
	canvas.draw_set_transform(Vector2.ZERO)
