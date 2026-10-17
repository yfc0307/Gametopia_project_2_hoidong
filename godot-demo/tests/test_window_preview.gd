extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	ui.start_day()
	var mask: Control = ui.get_node("Shop/WindowMask")
	assert(mask.clip_contents)
	await create_timer(1.0).timeout
	root.get_texture().get_image().save_png("res://tests/window_entry.png")
	await create_timer(7.0).timeout
	ui.sync_ui()
	for i in range(3):
		assert(not ui.get_node("Shop/WindowMask/Customers/Customer%d" % i).entering)
		assert(ui.get_node("Shop/WindowMask/Customers/Customer%d/OrderCard" % i).visible)
	root.get_texture().get_image().save_png("res://tests/window_arrived.png")
	print("WINDOW PREVIEW PASSED")
	quit()
