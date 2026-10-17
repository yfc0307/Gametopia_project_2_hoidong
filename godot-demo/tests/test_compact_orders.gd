extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	ui.start_day()
	for i in range(3):
		ui.game.customers[i] = ui.game.make_customer()
		ui.game.customers[i].tea = -1 if i == 0 else i
		ui.game.customers[i].tea_done = i == 0
		ui.game.customers[i].eggs = 2 if i != 1 else 0
	ui.sync_ui()
	await create_timer(8.0).timeout
	ui.sync_ui()
	for i in range(6): await process_frame
	var eggs = ui.get_node("Shop/WindowMask/Customers/Customer0/OrderCard")
	var tea = ui.get_node("Shop/WindowMask/Customers/Customer1/OrderCard")
	var mixed = ui.get_node("Shop/WindowMask/Customers/Customer2/OrderCard")
	assert(not eggs.get_node("Bubble/Items/TeaRow").visible)
	assert(not tea.get_node("Bubble/Items/EggRow").visible)
	assert(eggs.size.y < mixed.size.y and tea.size.y < mixed.size.y)
	assert(eggs.get_node("Bubble/Items/EggRow").position.y == 0)
	ui.paused = false
	ui.sync_ui()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/compact_orders.png")
	print("COMPACT ORDERS PASSED: eggs-only, tea-only, mixed, no empty product rows")
	quit()
