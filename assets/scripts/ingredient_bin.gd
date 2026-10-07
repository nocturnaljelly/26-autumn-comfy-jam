class_name IngredientBin
extends Control

@export var piece_size := 18.0
@export_range(0.0, 1.0) var pile_height := 0.7
@export var preview_size := 56.0
@export var hover_lift := 3.0
@export var hover_duration := 0.15
@export var disabled_tint := Color(0.7, 0.7, 0.7)

var ingredient: Ingredient:
	set(value):
		ingredient = value
		if is_node_ready():
			_refresh()
var disabled := false:
	set(value):
		disabled = value
		if is_node_ready():
			_update_state()

var _pieces: Array[PilePiece] = []
var _hovered := false
var _lift_tween: Tween
var _bounce_tween: Tween

@onready var pile: Control = %Pile
@onready var name_tag: Label = %NameTag


class PilePiece:
	var position: Vector2
	var angle: float
	var scale: float
	var tint: Color


func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	pile.draw.connect(_draw_pile)
	pile.resized.connect(_build_pile)
	_refresh()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled or not ingredient:
		return null
	set_drag_preview(_create_drag_preview())
	_bounce_pile()
	return ingredient

func _refresh() -> void:
	name_tag.text = ingredient.display_name if ingredient else ""
	tooltip_text = ingredient.description if ingredient else ""
	_build_pile()
	_update_state()

func _set_hovered(value: bool) -> void:
	_hovered = value
	_update_state()

func _update_state() -> void:
	var active := ingredient != null and not disabled
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if active else CURSOR_ARROW
	modulate = Color.WHITE if active else disabled_tint
	if _lift_tween:
		_lift_tween.kill()
	_lift_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_lift_tween.tween_property(pile, "position:y", -hover_lift if active and _hovered else 0.0, hover_duration)

func _build_pile() -> void:
	_pieces.clear()
	if ingredient:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(ingredient.id)
		var area := pile.size
		var spacing := piece_size * 0.55
		var y := area.y * (1.0 - pile_height) + piece_size * 0.3
		var row := 0
		while y < area.y - piece_size * 0.35:
			var x := piece_size * 0.4 + (spacing / 2 if row % 2 else 0.0)
			while x < area.x - piece_size * 0.4:
				var jitter := Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3)) * spacing
				var piece := PilePiece.new()
				piece.position = Vector2(x, y) + jitter
				piece.angle = rng.randf() * TAU
				piece.scale = rng.randf_range(0.85, 1.15)
				var shade := rng.randf_range(0.88, 1.08)
				piece.tint = Color(shade, shade, shade)
				if piece.position.y > _surface_y(piece.position.x, area):
					_pieces.append(piece)
				x += spacing
			y += spacing * 0.6
			row += 1
	pile.queue_redraw()

func _surface_y(x: float, area: Vector2) -> float:
	var from_center := x / area.x * 2.0 - 1.0
	return area.y * (1.0 - pile_height * (1.0 - 0.35 * from_center * from_center))

func _draw_pile() -> void:
	for piece in _pieces:
		IngredientPiece.draw_piece(pile, ingredient, piece.position, piece_size * piece.scale, piece.angle, piece.tint)

func _bounce_pile() -> void:
	pile.pivot_offset = Vector2(pile.size.x / 2, pile.size.y)
	pile.scale = Vector2(1.05, 0.9)
	if _bounce_tween:
		_bounce_tween.kill()
	_bounce_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(pile, "scale", Vector2.ONE, 0.25)

func _create_drag_preview() -> Control:
	var piece := IngredientPiece.new()
	piece.ingredient = ingredient
	piece.show_shadow = true
	piece.pop_duration = 0.2
	piece.sway_degrees = 12.0
	piece.mouse_filter = MOUSE_FILTER_IGNORE
	piece.size = Vector2.ONE * preview_size
	piece.position = -piece.size / 2
	var holder := Control.new()
	holder.mouse_filter = MOUSE_FILTER_IGNORE
	holder.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	holder.add_child(piece)
	return holder
