extends SceneTree
func _init() -> void:
	call_deferred("run")
func capture(tag: String) -> Image:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var img=root.get_texture().get_image();img.save_png("res://tests/sunlight_strength_"+tag+".png");return img
func run() -> void:
	var ui=load("res://main.tscn").instantiate();root.add_child(ui);ui.set_process(false)
	ui.save_path="user://sun_strength_test_only.json";ui.start_upgrade_test([]);ui.paused=false;ui.sync_ui()
	var sun=ui.get_node("Shop/WindowSunlight");sun.cloud_amount=0;sun.frozen=true
	sun.sunlight_energy=0;var dark=await capture("0")
	sun.sunlight_energy=.8;var medium=await capture("08")
	sun.sunlight_energy=2;var bright=await capture("2")
	var gain_medium:=0.0;var gain_bright:=0.0;var count:=0
	for y in range(320,540,4):
		for x in range(210,900,4):
			var a=dark.get_pixel(x,y);var b=medium.get_pixel(x,y);var c=bright.get_pixel(x,y)
			gain_medium+=(b.r+b.g+b.b-a.r-a.g-a.b)/3.0
			gain_bright+=(c.r+c.g+c.b-a.r-a.g-a.b)/3.0;count+=1
	gain_medium/=count;gain_bright/=count
	assert(gain_medium>.025 and gain_bright>gain_medium*1.3,"energy must visibly increase illumination")
	print("PASS: average counter brightness gain 0.8=",gain_medium,"; 2.0=",gain_bright)
	quit()
