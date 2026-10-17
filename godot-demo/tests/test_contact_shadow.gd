extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui); ui.set_process(false)
	ui.save_path = "user://contact_shadow_test_only.json"
	ui.start_day(); ui.paused = false; ui.sync_ui()
	await process_frame
	var kettle = ui.get_node("Shop/Kettles/Kettle0")
	var art = kettle.get_node("Design/Art")
	var shadow = kettle.get_node("Design/ContactShadow")
	assert(shadow.size.is_equal_approx(art.size + Vector2(0,12)))
	var original: Transform2D = art.get_global_transform()
	var position_before: Vector2 = kettle.position
	var scale_before: Vector2 = kettle.scale
	kettle.position += Vector2(30,-15); kettle.scale *= 1.1
	await process_frame
	assert(shadow.get_global_transform().is_equal_approx(art.get_global_transform()), "shadow must follow parent and artwork")
	kettle.position = position_before; kettle.scale = scale_before
	await process_frame
	assert(art.get_global_transform().is_equal_approx(original), "authored layout preserved")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/contact_shadow_rest.png")
	ui.begin_drag(ui.rect_of("Shop/Kettles/Kettle0/Design/Art").get_center())
	assert(ui.drag == "kettle")
	ui.drag_visual_pos += Vector2(35,-45); ui.sync_ui()
	await create_timer(.3).timeout
	assert(shadow.lift_amount > .9, "pickup must soften source shadow")
	assert(ui.get_node("Shop/Effects/DragGhost/ContactShadow").lift_amount > .9)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/contact_shadow_lift.png")
	ui.finish_drag(Vector2(-100,-100)); ui.return_time = 0; ui.return_item = ""; ui.sync_ui()
	await create_timer(.4).timeout
	assert(shadow.lift_amount < .01, "drop must restore contact shadow")
	assert(art.get_global_transform().is_equal_approx(original))
	print("PASS: reusable shadows, authored transforms, parent movement/scale, pickup and landing")
	ui.queue_free(); quit()
