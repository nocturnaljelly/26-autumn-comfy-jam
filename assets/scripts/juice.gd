class_name Juice
extends RefCounted


static func punch_scale(node: Control, amount: Vector2, duration := 0.45, pivot := Vector2(0.5, 0.5), transition := Tween.TRANS_BACK) -> void:
	var tween := _restart(node, &"juice_scale")
	node.pivot_offset = node.size * pivot
	node.scale = Vector2.ONE + amount
	tween.tween_property(node, "scale", Vector2.ONE, duration).set_trans(transition).set_ease(Tween.EASE_OUT)

static func pulse_scale(node: Control, amount := 0.02, duration := 1.0, steps := 3) -> void:
	var tween := _restart(node, &"juice_scale")
	node.pivot_offset = node.size / 2.0
	for i in steps:
		tween.tween_property(node, "scale", Vector2.ONE * (1.0 + amount), duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(node, "scale", Vector2.ONE, duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
static func shake_rotation(node: Control, degrees := 4.0, duration := 0.4, pivot := Vector2(0.5, 0.5), steps := 6) -> void:
	var tween := _restart(node, &"juice_rotation").set_trans(Tween.TRANS_SINE)
	node.pivot_offset = node.size * pivot
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		tween.tween_property(node, "rotation_degrees", degrees * falloff * (1.0 if i % 2 == 0 else -1.0), duration / (steps + 1))
	tween.tween_property(node, "rotation_degrees", 0.0, duration / (steps + 1))

static func shake_position(node: Control, strength := 3.0, duration := 0.25, steps := 6) -> void:
	var origin: Vector2 = node.get_meta(&"juice_origin", node.position)
	node.set_meta(&"juice_origin", origin)
	var tween := _restart(node, &"juice_position")
	for i in steps:
		var falloff := 1.0 - float(i) / steps
		tween.tween_property(node, "position", origin + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * falloff, duration / (steps + 1))
	tween.tween_property(node, "position", origin, duration / (steps + 1))
	tween.tween_callback(node.remove_meta.bind(&"juice_origin"))

static func burst(scene: PackedScene, parent: CanvasItem, at: Vector2) -> Node2D:
	if not scene:
		return null
	var particles: Node2D = scene.instantiate()
	particles.position = parent.get_global_transform().affine_inverse() * at
	parent.add_child(particles)
	return particles

static func pulse_alpha(node: Control, max_alpha := 0.3, duration := 0.5, steps := 3) -> void:
	var tween := _restart(node, &"juice_alpha")
	node.modulate.a = 0.0
	for i in steps:
		tween.tween_property(node, "modulate:a", max_alpha, duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(node, "modulate:a", 0.0, duration / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

static func _restart(node: Node, key: StringName) -> Tween:
	var previous: Tween = node.get_meta(key) if node.has_meta(key) else null
	if previous:
		previous.kill()
	var tween := node.create_tween()
	node.set_meta(key, tween)
	return tween
