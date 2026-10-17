extends SceneTree
const Main = preload("res://main.tscn")
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = Main.instantiate()
	root.add_child(ui)
	ui.set_process(false)
	ui.save_path = "res://tests/upgrade_test_progress.json"
	assert(ui.get_node("Shop/EggSupply").position.is_equal_approx(Vector2(107,308)))
	assert(ui.get_node("Shop/WarmingPot").position.is_equal_approx(Vector2(194,434)))
	assert(ui.get_node("Shop/BowlSupply").position.is_equal_approx(Vector2(312.00006,353)))
	ui.money = 3000; ui.owned_upgrades = []; ui.show_upgrades()
	ui.purchase_upgrade("fish_fast"); assert(ui.owned_upgrades.is_empty())
	for key in ui.UPGRADE_IDS: ui.purchase_upgrade(key)
	assert(ui.owned_upgrades.size() == 6)
	var saved: String = FileAccess.get_file_as_string(ui.save_path)
	ui.show_map(); ui.test_all(); assert(ui.test_mode and ui.game.upgrades.size() == 6)
	var money_before: int = ui.money
	ui.on_paid(100,true); ui.save_progress()
	assert(ui.money == money_before and FileAccess.get_file_as_string(ui.save_path) == saved)
	ui.game.tick(7)
	var raw: Vector2 = ui.rect_of("Shop/UpgradeStations/Fish/Raw").get_center()
	var lane: Vector2 = ui.rect_of("Shop/UpgradeStations/Fish/Boiler/Lane0").get_center()
	ui.begin_drag(raw); assert(ui.drag == "raw_fish"); ui.finish_drag(lane)
	assert(ui.game.lanes[0].size() == 6)
	var sticks: Vector2 = ui.rect_of("Shop/UpgradeStations/Fish/Sticks").get_center()
	var assembly: Vector2 = ui.rect_of("Shop/UpgradeStations/Fish/Assembly").get_center()
	ui.begin_drag(sticks); assert(ui.drag == "new_skewer"); ui.finish_drag(assembly)
	assert(ui.game.skewer_count == 0)
	ui.game.tick(6)
	ui.begin_drag(ui.rect_of("Shop/UpgradeStations/Fish/Boiler/Lane0/Ball0").get_center())
	assert(ui.game.fish_pending == 1); ui.game.tick(.18); ui.game.tick(.35); ui.game.tick(.25)
	ui.begin_drag(assembly); assert(ui.drag == "fish"); ui.finish_drag(ui.bin_zone.get_center())
	assert(ui.game.skewer_count == -1)
	ui.begin_drag(ui.rect_of("Shop/Kettles/Kettle0/Design/AutoBowl").get_center()); assert(ui.drag == "tea")
	ui.finish_drag(Vector2(600,50)); assert(ui.game.auto_slots[0].state == "full")
	ui.cancel_drag()
	for i in range(3):
		ui.game.customers[i].present = true
		ui.game.customers[i]["arriving"] = false
		ui.get_node("Shop/WindowMask/Customers/Customer%d" % i).walk_speed = 240.0
	ui.paused = false; ui.sync_ui()
	await create_timer(2).timeout
	ui.paused = false; ui.sync_ui()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/upgrades_shop.png")
	ui.show_map()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/upgrades_map.png")
	ui.show_upgrades()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/upgrades_menu.png")
	ui.show_map(); ui.start_day(); assert(not ui.test_mode and ui.game.upgrades.size() == 6)
	print("PASS: purchase prerequisites, persistence, isolated test income, six-upgrade scene and menu")
	quit()
