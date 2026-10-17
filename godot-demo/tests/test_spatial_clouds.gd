extends SceneTree
func _init() -> void:call_deferred("run")
func capture() -> Image:
	await process_frame;await process_frame;await process_frame;await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	var ui=load("res://main.tscn").instantiate();root.add_child(ui);ui.set_process(false)
	ui.save_path="user://spatial_cloud_test_only.json";ui.start_upgrade_test([]);ui.paused=false;ui.sync_ui()
	var sun=ui.get_node("Shop/WindowSunlight");sun.frozen=true
	sun.sunlight_energy=.2 # Isolated low-light regression, without changing saved scene settings.
	sun.elapsed=0;var first=await capture();first.save_png("res://tests/clouds_0.png")
	sun.elapsed=4;var second=await capture();second.save_png("res://tests/clouds_4.png")
	var changed:=0
	for y in range(300,550,3):
		for x in range(180,950,3):
			var a=first.get_pixel(x,y);var b=second.get_pixel(x,y)
			if absf(a.r+a.g+a.b-b.r-b.g-b.b)>.025:changed+=1
	assert(changed>100,"clouds must visibly move across counter even at current energy")
	var last:float=sun.elapsed;await create_timer(.2).timeout;assert(sun.elapsed==last)
	print("PASS: moving cloud pattern at current energy; changed counter samples=",changed,"; pause preserves cloud phase")
	quit()
