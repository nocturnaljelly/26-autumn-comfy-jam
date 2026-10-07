class_name CupView
extends Control

signal ingredient_dropped(ingredient: Ingredient)

const HIGHLIGHT_COLOR := Color(0.98, 0.68, 0.22)

var is_full := false

var _accepting_drag := false
var _drag_time := 0.0
var _highlight := StyleBoxFlat.new()


func _ready() -> void:
	_highlight.set_border_width_all(5)
	_highlight.set_corner_radius_all(10)
	set_process(false)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Ingredient and not is_full

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	ingredient_dropped.emit(data)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			_accepting_drag = _can_drop_data(Vector2.ZERO, get_viewport().gui_get_drag_data())
			_drag_time = 0.0
			set_process(_accepting_drag)
			queue_redraw()
		NOTIFICATION_DRAG_END:
			_accepting_drag = false
			set_process(false)
			queue_redraw()

func _process(delta: float) -> void:
	_drag_time += delta
	queue_redraw()

func _draw() -> void:
	if not _accepting_drag:
		return
	var hovered := get_global_rect().has_point(get_global_mouse_position())
	var pulse := 0.775 + 0.225 * sin(_drag_time * 6.0)
	_highlight.border_color = Color(HIGHLIGHT_COLOR, 1.0 if hovered else pulse)
	_highlight.bg_color = Color(HIGHLIGHT_COLOR, 0.2 if hovered else 0.0)
	draw_style_box(_highlight, Rect2(Vector2.ZERO, size).grow(3.0))
