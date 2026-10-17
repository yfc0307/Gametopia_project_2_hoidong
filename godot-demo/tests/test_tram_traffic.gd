extends SceneTree
func _init() -> void:call_deferred("run")
func capture(tag: String) -> Image:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var img=root.get_texture().get_image();img.save_png("res://tests/tram_"+tag+".png");return img
func run() -> void:
	var ui=load("res://main.tscn").instantiate();root.add_child(ui);ui.set_process(false)
	ui.save_path="user://tram_test_only.json";ui.start_upgrade_test([]);ui.paused=false;ui.sync_ui()
	var sun=ui.get_node("Shop/WindowSunlight");sun.cloud_amount=0;sun.frozen=false
	var traffic=ui.get_node("Shop/WindowMask/TramTraffic");traffic.set_process(false)
	assert(traffic.wait_left>=4 and traffic.wait_left<=8 and not traffic.moving)
	var empty=await capture("empty")
	traffic.wait_left=0;traffic._process(.016);assert(traffic.moving and traffic.get_node("Tram").visible)
	var before:float=traffic.get_node("Tram").position.x;traffic._process(.5);assert(traffic.get_node("Tram").position.x>before)
	traffic.get_node("Tram").position.x=250;traffic._process(.5)
	assert(traffic.get_node("Tram/Art").is_visible_in_tree())
	var passing=await capture("passing")
	var occ=traffic.get_node("Tram/Art/SunOccluder");assert(occ.visible and occ.occluder.polygon.size()>3)
	var darkened:=0
	for y in range(310,540,4):
		for x in range(180,950,4):
			var a=empty.get_pixel(x,y);var b=passing.get_pixel(x,y)
			if (a.r+a.g+a.b-b.r-b.g-b.b)/3.0>.08:darkened+=1
	assert(darkened>20,"tram must cast a local moving shadow")
	for i in range(3):
		var slot=ui.get_node("Shop/WindowMask/Customers/Customer%d"%i)
		slot.get_node("Avatar").position=slot.home_avatar;slot.get_node("Avatar").visible=true
	await capture("customers_in_front")
	sun.frozen=true;before=traffic.get_node("Tram").position.x;traffic._process(1);assert(traffic.get_node("Tram").position.x==before)
	sun.frozen=false;traffic._process(30);assert(not traffic.moving and not traffic.get_node("Tram").visible)
	assert(traffic.wait_left>=12 and traffic.wait_left<=24)
	await process_frame;assert(not occ.visible)
	print("PASS: random arrival, left-to-right travel, window silhouette, broad contrast pixels=",darkened,"; pause, exit and restoration")
	quit()
