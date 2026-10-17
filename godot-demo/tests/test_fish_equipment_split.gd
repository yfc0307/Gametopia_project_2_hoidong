extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var old = load("res://tests/fish_layout_before.tscn").instantiate()
	var page = load("res://scenes/pages/tea_shop.tscn").instantiate()
	root.add_child(old); root.add_child(page); await process_frame
	var checked := 0
	for node in old.find_children("*", "Control", true, false):
		var path: String = str(old.get_path_to(node))
		path = path.replace("UpgradeStations/Fish/Lane", "UpgradeStations/Fish/Boiler/Lane").replace("UpgradeStations/Fish/WarmerArt", "UpgradeStations/Fish/Boiler/WarmerArt")
		var current = page.get_node(path)
		assert(node.get_global_transform().is_equal_approx(current.get_global_transform()),path+" transform")
		assert(node.size.is_equal_approx(current.size),path+" size")
		checked += 1
	old.queue_free();page.queue_free();await process_frame
	var ui = load("res://main.tscn").instantiate();root.add_child(ui);ui.set_process(false)
	ui.save_path = "user://fish_split_test_only.json";ui.start_upgrade_test(["fish"]);ui.paused=false
	var fish = ui.get_node("Shop/UpgradeStations/Fish")
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/fish_split_layout.png")
	var positions := {}
	for pair in [["Raw",Vector2(210,180)],["Sticks",Vector2(20,180)],["Assembly",Vector2(90,160)],["Boiler",Vector2(-20,0)]]:
		var equipment: Control = fish.get_node(pair[0]);assert(not equipment.scene_file_path.is_empty())
		equipment.position=pair[1];equipment.scale=Vector2(.9,.9);positions[pair[0]]=equipment.position
	ui.sync_ui();await process_frame
	var raw: Vector2=ui.rect_of("Shop/UpgradeStations/Fish/Raw").get_center()
	var lane: Vector2=ui.rect_of("Shop/UpgradeStations/Fish/Boiler/Lane0").get_center()
	assert(ui.begin_upgrade_drag(raw));assert(ui.drag=="raw_fish");ui.finish_drag(lane);assert(ui.game.lanes[0].size()==2)
	assert(ui.begin_upgrade_drag(ui.rect_of("Shop/UpgradeStations/Fish/Sticks").get_center()));assert(ui.drag=="new_skewer")
	ui.finish_drag(ui.rect_of("Shop/UpgradeStations/Fish/Assembly").get_center());assert(ui.game.skewer_count==0)
	ui.game.tick(6);ui.sync_ui()
	assert(ui.begin_upgrade_drag(ui.rect_of("Shop/UpgradeStations/Fish/Boiler/Lane0/Ball0").get_center()))
	assert(ui.game.fish_pending==1);ui.game.tick(.18);ui.game.tick(.35);ui.sync_ui()
	ui.game.tick(.125);ui.sync_ui()
	var flight: TextureRect = fish.get_node("FlyingSkewer")
	var source: Control = fish.get_node("Boiler/Lane0")
	var skewer: Control = fish.get_node("Assembly/Skewer")
	var from: Vector2 = fish.get_global_transform().affine_inverse()*source.get_global_transform()*Vector2(15,-20)
	var to: Vector2 = fish.get_global_transform().affine_inverse()*skewer.global_position
	assert(flight.position.is_equal_approx(from.lerp(to,.5)),"flight follows moved and scaled equipment")
	ui.game.tick(.125);ui.sync_ui();assert(not ui.game.fish_in_machine)
	for key in positions:assert(fish.get_node(key).position.is_equal_approx(positions[key]),"controller preserves manual placement")
	assert(ui.begin_upgrade_drag(ui.rect_of("Shop/UpgradeStations/Fish/Assembly").get_center()));assert(ui.drag=="fish");ui.finish_drag(ui.bin_zone.get_center());assert(ui.game.skewer_count == -1)
	print("PASS: preserved ",checked," controls; four independently movable equipment scenes; cooking, assembly, flight, pickup and trash follow edited transforms")
	quit()
