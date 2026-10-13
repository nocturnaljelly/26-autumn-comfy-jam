extends CanvasLayer

@onready var fade: ColorRect = %Fade

func fade_in_out() -> void: 
	await fade_out()
	await fade_in()

func fade_out() -> void:
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	await create_tween().tween_property(fade, "color:a", 1.0, 0.5).finished

func fade_in(delay: float = 0.0) -> void: 
	await get_tree().create_timer(delay).timeout
	await create_tween().tween_property(fade, "color:a", 0.0, 1.0).finished
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
