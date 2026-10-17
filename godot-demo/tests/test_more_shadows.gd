extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui); ui.set_process(false)
	ui.save_path = "user://shadow_coverage_test_only.json"
	ui.start_upgrade_test(["jelly","siumai"]); ui.paused = false; ui.sync_ui()
	await process_frame
	for path in ["CookingPot/Design/Art","WarmingPot/Design/Art","UpgradeStations/Jelly/Item0","UpgradeStations/Jelly/Item3","UpgradeStations/Siumai/Basket","UpgradeStations/Siumai/Item5"]:
		var visual = ui.get_node("Shop/"+path)
		assert(visual.has_node("ContactShadow"),path)
		assert(visual.get_node("ContactShadow").get_target() == visual)
		assert(visual.get_node("ContactShadow").shadow_color.a > .7, "preserve Nicole's opacity")
	var bowl = ui.get_node("Shop/FillingSlot/Design/EmptyBowl")
	assert(not bowl.get_node("ContactShadow").is_visible_in_tree())
	ui.game.place_bowl(); ui.sync_ui(); await process_frame
	assert(bowl.get_node("ContactShadow").is_visible_in_tree())
	ui.game.pour(0); ui.game.tick(1.2); ui.sync_ui(); await process_frame
	assert(not bowl.get_node("ContactShadow").is_visible_in_tree())
	assert(ui.get_node("Shop/FillingSlot/Design/FullBowl/ContactShadow").is_visible_in_tree())
	ui.game.jelly = 0; ui.game.siumai = 0; ui.sync_ui(); await process_frame
	assert(not ui.get_node("Shop/UpgradeStations/Jelly/Item0/ContactShadow").is_visible_in_tree())
	assert(not ui.get_node("Shop/UpgradeStations/Siumai/Item0/ContactShadow").is_visible_in_tree())
	ui.game.jelly = 4; ui.game.siumai = 6; ui.sync_ui(); await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/more_contact_shadows.png")
	print("PASS: equipment and food shadows, preserved opacity, bowl states and sold-out visibility")
	quit()
