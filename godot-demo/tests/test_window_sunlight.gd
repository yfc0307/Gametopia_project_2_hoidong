extends SceneTree
var ui: Control
func _init() -> void:
	call_deferred("run")
func snapshot(tag: String) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	img.save_png("res://tests/sunlight_"+tag+".png")
	return img
func run() -> void:
	ui=load("res://main.tscn").instantiate();root.add_child(ui);ui.set_process(false)
	ui.save_path="user://sunlight_test_only.json";ui.start_upgrade_test([]);ui.paused=false;ui.sync_ui()
	var sunlight = ui.get_node("Shop/WindowSunlight")
	sunlight.cloud_amount=0;sunlight.frozen=true
	for i in range(3):
		var slot=ui.get_node("Shop/WindowMask/Customers/Customer%d"%i)
		if slot.motion:slot.motion.kill();slot.motion=null
		slot.get_node("Avatar").visible=false;slot.get_node("OrderCard").visible=false
	var empty=await snapshot("empty")
	for i in range(3):
		var slot=ui.get_node("Shop/WindowMask/Customers/Customer%d"%i)
		slot.get_node("Avatar").position=slot.home_avatar;slot.get_node("Avatar").visible=true
	var blocked=await snapshot("customers")
	var difference := 0.0
	var darker_pixels := 0
	for y in range(int(empty.get_height()*.42),int(empty.get_height()*.76),4):
		for x in range(int(empty.get_width()*.12),int(empty.get_width()*.85),4):
			var a=empty.get_pixel(x,y);var b=blocked.get_pixel(x,y)
			var delta:float=(a.r+a.g+a.b-b.r-b.g-b.b)/3.0
			difference+=absf(delta)
			if delta>.012:darker_pixels+=1
	assert(darker_pixels>20,"customers must actually block sunlight on the counter")
	var shaded_item_pixels := 0
	for k in range(5):
		var visual: TextureRect = ui.get_node("Shop/Kettles/Kettle%d/Design/Art"%k)
		var source_image := visual.texture.get_image()
		var rect: Rect2 = ui.rect_of("Shop/Kettles/Kettle%d/Design/Art"%k)
		for y in range(int(rect.position.y),int(rect.end.y)):
			for x in range(int(rect.position.x),int(rect.end.x)):
				var uv: Vector2 = (Vector2(x,y)-rect.position)/rect.size
				var alpha := source_image.get_pixel(clampi(int(uv.x*source_image.get_width()),0,source_image.get_width()-1),clampi(int(uv.y*source_image.get_height()),0,source_image.get_height()-1)).a
				if alpha < .85: continue
				var a=empty.get_pixel(x,y);var b=blocked.get_pixel(x,y)
				if (a.r+a.g+a.b-b.r-b.g-b.b)/3.0>.003:shaded_item_pixels+=1
	print("Verified occluded opaque equipment pixels: ",shaded_item_pixels)
	assert(shaded_item_pixels>5,"customers must affect equipment backlighting")
	var avatar=ui.get_node("Shop/WindowMask/Customers/Customer0/Avatar")
	var occluder=avatar.get_node("SunOccluder")
	assert(occluder.visible and occluder.occluder.polygon.size()>3)
	avatar.position.x-=160
	var moving=await snapshot("moving")
	var moved_shadow_pixels := 0
	for y in range(int(blocked.get_height()*.42),int(blocked.get_height()*.76),6):
		for x in range(int(blocked.get_width()*.12),int(blocked.get_width()*.85),6):
			var a=blocked.get_pixel(x,y);var b=moving.get_pixel(x,y)
			if absf(a.r+a.g+a.b-b.r-b.g-b.b)>.012:moved_shadow_pixels+=1
	assert(moved_shadow_pixels>20,"shadow must move with customer")
	avatar.visible=false;await process_frame;assert(not occluder.visible)
	var previous:float=sunlight.elapsed;sunlight.frozen=true;await create_timer(.1).timeout;assert(sunlight.elapsed==previous)
	sunlight.frozen=false;await create_timer(.1).timeout;assert(sunlight.elapsed>previous)
	print("PASS: actual customer shadow pixels=",darker_pixels,"; silhouette follows movement and hiding; pause freezes cloud time")
	quit()
