extends SceneTree
func _init() -> void:call_deferred("run")
func capture(tag: String) -> Image:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var img=root.get_texture().get_image();img.save_png("res://tests/tram_local_"+tag+".png");return img
func run() -> void:
	var ui=load("res://main.tscn").instantiate();root.add_child(ui);ui.set_process(false)
	ui.save_path="user://tram_local_test_only.json";ui.start_upgrade_test([]);ui.paused=false;ui.sync_ui()
	var sun=ui.get_node("Shop/WindowSunlight");sun.cloud_amount=0;sun.frozen=false
	var traffic=ui.get_node("Shop/WindowMask/TramTraffic");traffic.set_process(false)
	var original_energy:float=sun.sunlight_energy
	await capture("empty")
	traffic.travel_speed=900;traffic.speed_variation=0;traffic.start_pass()
	var x:float=traffic.get_node("Tram").position.x;traffic._process(.1)
	assert(is_equal_approx(traffic.get_node("Tram").position.x-x,90),"speed above old limit works")
	traffic.get_node("Tram").position.x=150;traffic.update_projection(sun);print("projection=",traffic.projection," visible=",traffic.projection.visible," rect=",traffic.projection.get_global_rect());var left=await capture("left")
	assert(is_equal_approx(sun.get_node("Sun").energy,original_energy),"tram must not dim entire sunlight")
	traffic.get_node("Tram").position.x=450;traffic.update_projection(sun);var right=await capture("right")
	var differences:=0
	var near_black_pixels:=0
	for y in range(300,550,4):
		for x2 in range(180,950,4):
			var a=left.get_pixel(x2,y);var b=right.get_pixel(x2,y)
			if absf(a.r+a.g+a.b-b.r-b.g-b.b)>.02:differences+=1
			if minf((a.r+a.g+a.b)/3.0,(b.r+b.g+b.b)/3.0)<.12:near_black_pixels+=1
	assert(near_black_pixels>50,"shadow must be visibly close to black")
	assert(differences>50,"local projected shadow must move with tram")
	assert(is_equal_approx(sun.get_node("Sun").energy,original_energy))
	traffic._process(10);assert(not traffic.moving and not ui.get_node("Shop/TramShadowProjection").visible)
	print("PASS: 900 px/sec, constant sunlight energy, moving silhouette shadow samples=",differences)
	quit()
