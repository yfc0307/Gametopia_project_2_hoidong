extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	var slot = ui.get_node("Shop/WindowMask/Customers/Customer0")
	var authored: Transform2D = slot.get_transform()
	var home: Vector2 = slot.get_node("Avatar").position
	ui.start_day()
	assert(not slot.get_node("OrderCard").visible)
	assert(slot.entering and slot.get_node("Avatar").position.x < home.x)
	ui.paused = true
	ui.sync_ui()
	var paused_position: Vector2 = slot.get_node("Avatar").position
	await create_timer(0.15).timeout
	assert(slot.get_node("Avatar").position.is_equal_approx(paused_position))
	ui.paused = false
	ui.sync_ui()
	await create_timer(8.0).timeout
	assert(not slot.entering and slot.get_node("Avatar").position.is_equal_approx(home))
	assert(slot.get_transform().is_equal_approx(authored))
	for complete in [true, false]:
		ui.game.settle(0, complete)
		ui.sync_ui()
		assert(not slot.get_node("OrderCard").visible)
		assert(slot.get_node("Avatar").visible, "departure must not instantly disappear")
		await create_timer(8.0).timeout
		assert(not slot.get_node("Avatar").visible)
		assert(slot.get_node("Waiting").visible)
		ui.game.customers[0] = ui.game.make_customer()
		ui.sync_ui()
		assert(slot.entering)
		await create_timer(8.0).timeout
		assert(slot.get_node("Avatar").position.is_equal_approx(home))
		assert(slot.get_transform().is_equal_approx(authored))
	ui.start_day()
	assert(slot.entering, "next day must animate entrance again")
	print("CUSTOMER MOTION PASSED: entrance, pause/resume, completed/expired exits, respawn, next day, preserved root")
	quit()
