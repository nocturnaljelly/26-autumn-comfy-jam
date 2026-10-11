class_name IngredientBin
extends Control

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

var _hovered := false
var _lift_tween: Tween
var _bounce_tween: Tween

@onready var pile: TextureRect = %Pile
@onready var name_tag: Label = %NameTag

func _ready() -> void:
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	_refresh()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled or not ingredient:
		return null
	set_drag_preview(_create_drag_preview())
	return ingredient

func _refresh() -> void:
	name_tag.text = ingredient.display_name if ingredient else ""
	pile.texture = ingredient.food_graphic if ingredient else null
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
