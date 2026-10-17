extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	ui.save_path = "user://revenue_hud_test_only.json"
	ui.start_upgrade_test([])
	ui.paused = false
	ui.sync_ui()
	await create_timer(.6).timeout
	var hud = ui.get_node("Shop/HUD")
	var number = hud.get_node("Money/Amount")
	var title = hud.get_node("Money")
	var title_rect: Rect2 = title.get_global_rect()
	var title_scale: Vector2 = title.scale
	var frame_rect: Rect2 = hud.get_node("MoneyCard").get_global_rect()
	var number_position: Vector2 = number.position
	var seen: Array[int] = []
	ui.game.earned = 15
	ui.sync_ui()
	var start := Time.get_ticks_msec()
	var enlarged := false
	var tilted := false
	while Time.get_ticks_msec() - start < 600:
		ui.sync_ui()
		await process_frame
		var value := int(number.get_parsed_text())
		if value not in seen: seen.append(value)
		enlarged = enlarged or number.scale.x > 1.1
		tilted = tilted or absf(number.rotation) > .04
		assert(title.get_global_rect() == title_rect and title.scale == title_scale, "caption remains fixed")
		assert(hud.get_node("MoneyCard").get_global_rect() == frame_rect, "frame remains fixed")
		assert(number.position == number_position, "number slot never moves")
	assert(enlarged and tilted and number.get_parsed_text() == "15")
	assert(seen.size() > 5 and seen[0] < 15, "intermediate numbers shown")
	assert(number.scale.is_equal_approx(number.base_scale) and is_equal_approx(number.rotation, number.base_rotation))
	assert(not hud.get_node("Orders").has_node("ValueJuice"))
	ui.game.earned = 30; ui.sync_ui()
	await create_timer(.1).timeout
	ui.game.earned = 45; ui.sync_ui()
	await create_timer(.1).timeout
	ui.paused = true; ui.sync_ui()
	var frozen_text: String = number.get_parsed_text()
	var frozen_scale: Vector2 = number.scale
	await create_timer(.2).timeout
	assert(number.get_parsed_text() == frozen_text and number.scale == frozen_scale, "pause freezes roll and bounce")
	ui.paused = false; ui.sync_ui()
	await create_timer(.6).timeout
	assert(number.get_parsed_text() == "45" and number.scale.is_equal_approx(number.base_scale))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/hk_hud_preview.png")
	ui.start_upgrade_test([])
	assert(number.get_parsed_text() == "0" and number.scale.is_equal_approx(number.base_scale), "new day resets immediately")
	print("PASS: roll 0->15 observed ", seen, "; digits-only scale/tilt, fixed caption/frame/slot, interrupted income, pause and new-day reset")
	quit()
