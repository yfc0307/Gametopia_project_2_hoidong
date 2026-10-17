extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	ui.start_day()
	var customer = ui.get_node("Shop/Customers/Customer0")
	var old_transform: Transform2D = customer.get_transform()
	for face in range(4):
		ui.game.customers[0].face = face
		ui.game.customers[0].patience = 30.0
		ui.sync_ui()
		assert(customer.get_node("Avatar").texture == ui.CUSTOMER_PORTRAITS[face])
		assert(customer.get_node("OrderCard/Progress").fill_mode == 3)
		assert(is_equal_approx(customer.get_node("OrderCard/Progress").value, 50.0))
		assert(customer.get_transform().is_equal_approx(old_transform))
	for i in range(3):
		ui.game.customers[i].face = [0, 1, 3][i]
		ui.game.customers[i].patience = 60.0
		ui.game.customers[i].tea = i
		ui.game.customers[i].tea_done = false
		ui.game.customers[i].eggs = i + 1
	ui.sync_ui()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/customers.png")
	print("CUSTOMER REDESIGN PASSED: four portraits, vertical patience, preserved transforms")
	quit()
