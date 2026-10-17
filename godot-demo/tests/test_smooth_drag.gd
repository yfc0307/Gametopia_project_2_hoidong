extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	ui.start_day()
	ui.begin_drag(ui.kettle_rect(0).get_center())
	assert(ui.drag == "kettle")
	ui.paused = false
	var start: Vector2 = ui.drag_visual_pos
	# The smoothing factor is frame-rate independent; step size tracks distance.
	var a: float = 1.0 - exp(-ui.drag_follow_rate / 60.0)
	var target := start + Vector2(600, 0)
	var first := start.lerp(target, a)
	var second := first.lerp(target, a)
	assert(first.distance_to(start) > second.distance_to(first))
	var at_30 := start
	for i in range(30): at_30 = at_30.lerp(target, 1.0 - exp(-ui.drag_follow_rate / 30.0))
	var at_60 := start
	for i in range(60): at_60 = at_60.lerp(target, 1.0 - exp(-ui.drag_follow_rate / 60.0))
	assert(at_30.is_equal_approx(at_60))
	ui.drag_visual_pos = target
	ui.finish_drag(Vector2(1100, 650))
	assert(ui.return_pos.is_equal_approx(target))
	var distance: float = ui.return_pos.distance_to(ui.drag_origin)
	ui._process(0.05)
	assert(ui.return_pos.distance_to(ui.drag_origin) < distance)
	ui.cancel_drag()
	assert(ui.return_time == 0.0)
	print("SMOOTH DRAG PASSED: distance-based easing, frame-rate independence, continuous return, cancellation")
	quit()
