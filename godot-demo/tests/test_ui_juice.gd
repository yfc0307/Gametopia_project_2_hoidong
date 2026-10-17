extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	ui.save_path = "user://ui_juice_test_only.json"
	await create_timer(.65).timeout
	var effects: Array = []
	for node in ui.find_children("*", "Node", true, false):
		if node.get_script() and node.get_script().resource_path == "res://scripts/ui_juice.gd": effects.append(node)
	assert(effects.size() > 30, "native reusable components loaded")
	var button_fx
	for fx in effects:
		if fx.mode == 0 and fx.target.is_visible_in_tree() and not fx.target.disabled:
			button_fx = fx; break
	assert(button_fx != null)
	var button: Button = button_fx.target
	var authored_position: Vector2 = button.position
	var authored_scale: Vector2 = button_fx.base_scale
	button.mouse_entered.emit()
	await create_timer(.16).timeout
	assert(button.scale.x > authored_scale.x, "hover magnification")
	button.button_down.emit()
	await create_timer(.11).timeout
	assert(button.scale.x < authored_scale.x, "pressed compression")
	button.button_up.emit()
	button.mouse_exited.emit()
	await create_timer(.45).timeout
	assert(button.scale.is_equal_approx(authored_scale) and button.position == authored_position, "no layout drift")
	button.mouse_entered.emit()
	button.disabled = true
	await create_timer(.45).timeout
	assert(button.scale.is_equal_approx(authored_scale), "disabled button returns to baseline")
	button.disabled = false
	ui.show_upgrades()
	await create_timer(.08).timeout
	ui.show_map()
	await create_timer(.7).timeout
	for fx in effects:
		if fx.mode == 1: assert(fx.target.scale.is_equal_approx(fx.base_scale), "rapid navigation settles")
	ui.start_upgrade_test([])
	ui.paused = false
	ui.sync_ui()
	await create_timer(.7).timeout
	var label = ui.get_node("Shop/HUD/Money/Amount")
	var base_scale: Vector2 = label.base_scale
	label.set_amount(99)
	await create_timer(.1).timeout
	assert(label.scale.x > base_scale.x, "money change pulses")
	await create_timer(.5).timeout
	assert(label.scale.is_equal_approx(base_scale))
	ui.toggle_pause()
	await create_timer(.7).timeout
	ui.toggle_pause()
	ui.show_map()
	await create_timer(.7).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/ui_juice_preview.png")
	print("PASS: hover, press, disabled, rapid navigation, value pulse, pause and authored layout preservation; ", effects.size(), " components")
	quit()
