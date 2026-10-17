extends SceneTree
func _init() -> void:call_deferred("run")
func capture() -> Image:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	var ui=load("res://main.tscn").instantiate();root.add_child(ui);ui.set_process(false)
	ui.save_path="user://tram_downward_test_only.json";ui.start_upgrade_test([]);ui.paused=false;ui.sync_ui()
	var sun=ui.get_node("Shop/WindowSunlight");sun.frozen=true
	var traffic=ui.get_node("Shop/WindowMask/TramTraffic");traffic.set_process(false)
	traffic.start_pass();traffic.get_node("Tram").position.x=150;traffic.tram_shadow_darkness=.9
	var projection=ui.get_node("Shop/TramShadowProjection")
	projection.position=Vector2.ZERO;projection.size=Vector2(1280,600)
	traffic.update_projection(sun);projection.visible=false
	var baseline=await capture()
	traffic.update_projection(sun);var shadow=await capture()
	var above_changes:=0;var below_changes:=0
	for y in range(15,265,3):
		for x in range(15,1250,3):
			var a=baseline.get_pixel(x,y);var b=shadow.get_pixel(x,y)
			if absf(a.r+a.g+a.b-b.r-b.g-b.b)>.005:above_changes+=1
	for y in range(300,530,3):
		for x in range(150,1000,3):
			var a=baseline.get_pixel(x,y);var b=shadow.get_pixel(x,y)
			if (a.r+a.g+a.b-b.r-b.g-b.b)>.1:below_changes+=1
	assert(above_changes==0,"no reverse projection over window or tram even with effect at screen top")
	assert(below_changes>50,"downward local shadow remains")
	shadow.save_png("res://tests/tram_shadow_downward.png")
	print("PASS: above-window changed pixels=",above_changes,"; downward shadow samples=",below_changes)
	quit()
