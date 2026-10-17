extends SceneTree
const Main = preload("res://main.tscn")
var ui: Control
func _init() -> void:
	call_deferred("run")

func drag_to(source: Vector2, target: Vector2, expected: String) -> void:
	ui.begin_drag(source)
	assert(ui.drag == expected, "drag start: " + expected)
	ui.finish_drag(target)
	assert(ui.drag == "", "drag released")

func run() -> void:
	ui = Main.instantiate()
	ui.scale = Vector2(1.5, 1.5)
	root.add_child(ui)
	ui.set_process(false)
	ui.save_path = "res://tests/test_progress.json"
	ui.owned_upgrades = []
	ui.money = 0
	ui.day = 1
	assert(ui.screen == "map" and ui.buttons.size() >= 12)
	ui.buttons[0].pressed.emit()
	assert(ui.screen == "shop")
	ui.set_process(true)
	await create_timer(10.0).timeout
	ui.set_process(false)
	ui.sync_ui()
	var s = ui.game
	# Moving an authored parent moves its visual children and interaction rect.
	var slot: Control = ui.get_node("Shop/FillingSlot")
	var old_rect: Rect2 = ui.fill_zone
	var old_art: Vector2 = slot.get_node("Design/EmptyBowl").global_position
	slot.position += Vector2(90, -35)
	assert(ui.fill_zone.position.is_equal_approx(old_rect.position + Vector2(90, -35)), "filling hitbox follows node")
	assert(slot.get_node("Design/EmptyBowl").global_position.is_equal_approx(old_art + Vector2(135, -52.5)), "art follows parent")
	ui.sync_ui()
	assert(slot.position.is_equal_approx(old_rect.position + Vector2(90, -35)), "controller preserves authored layout")
	slot.position -= Vector2(90, -35)
	var pot: Control = ui.get_node("Shop/CookingPot")
	var old_pot: Rect2 = ui.pot_zone
	pot.position += Vector2(15, 0)
	assert(ui.pot_zone.position.is_equal_approx(old_pot.position + Vector2(15, 0)), "pot hitbox follows node")
	pot.position -= Vector2(15, 0)
	s.customers[0].tea = 0
	s.customers[0].tea_done = false
	s.customers[0].eggs = 1
	drag_to(ui.bowl_source.get_center(), Vector2(1050, 560), "new_bowl")
	assert(s.bowl == "absent" and ui.return_time > 0)
	drag_to(ui.bowl_source.get_center(), ui.fill_zone.get_center(), "new_bowl")
	assert(s.bowl == "empty")
	drag_to(ui.kettle_rect(0).get_center(), ui.fill_zone.get_center(), "kettle")
	assert(s.bowl == "pouring")
	ui.begin_drag(ui.fill_zone.get_center())
	assert(ui.drag == "", "pour locks bowl")
	s.tick(1.3)
	drag_to(ui.fill_zone.get_center(), ui.customer_rect(0).get_center(), "tea")
	assert(s.customers[0].tea_done and ui.money == 0)
	drag_to(ui.egg_zone.get_center(), ui.pot_zone.get_center(), "raw_eggs")
	assert(s.pot == "cooking" and s.raw_eggs == 0)
	ui.begin_drag(ui.phone_zone.get_center())
	assert(s.restock_left > 0 and ui.quip_left == 3)
	s.tick(8.1)
	assert(s.pot == "ready" and s.raw_eggs == 6)
	ui.begin_drag(ui.pot_zone.get_center())
	s.tick(0.41)
	assert(s.warm == 6)
	drag_to(ui.warm_zone.get_center(), ui.customer_rect(0).get_center(), "egg")
	assert(ui.money == 18 and s.earned == 18)
	drag_to(ui.warm_zone.get_center(), ui.bin_zone.get_center(), "egg")
	assert(s.warm == 4 and ui.bin_flash > 0)
	ui.toggle_pause()
	assert(ui.paused and ui.buttons.size() == 2)
	ui.toggle_pause()
	assert(not ui.paused and ui.buttons.size() == 1)
	s.left = 0.01
	s.tick(0.02)
	assert(ui.screen == "closing" and ui.day == 2)
	await create_timer(0.8).timeout
	assert(ui.screen == "summary" and ui.buttons.size() == 1)
	await process_frame
	root.get_texture().get_image().save_png("res://tests/summary.png")
	ui.buttons[0].pressed.emit()
	assert(ui.screen == "map" and ui.money == 18)
	ui.owned_upgrades = []
	ui.money = 0
	ui.load_progress()
	assert(ui.money == 18 and ui.day == 2, "save and reload")
	ui.start_day()
	assert(ui.game.raw_eggs == 6 and ui.game.warm == 0 and ui.game.earned == 0)
	print("UI INTEGRATION PASSED: map, invalid drop, bowl, pouring lock, tea delivery, egg cooking, phone, transfer, payment, trash, pause, closing, summary, return, save/reload, next day reset")
	ui.queue_free()
	await process_frame
	quit(0)
