extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate();root.add_child(ui);ui.set_process(false)
	ui.save_path = "user://pour_stream_preview_only.json";ui.start_upgrade_test([]);ui.paused=false
	ui.game.place_bowl();ui.game.pour(0);ui.sync_ui()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/pour_stream_fixed.png")
	print("POUR STREAM: ",ui.get_node("Shop/Effects/PourStream").points)
	quit()
