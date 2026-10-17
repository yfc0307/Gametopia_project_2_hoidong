extends SceneTree
func _init() -> void: call_deferred("run")
func changed(a: Image, b: Image, area: Rect2) -> int:
	var result := 0
	for y in range(int(area.position.y), int(area.end.y)):
		for x in range(int(area.position.x), int(area.end.x)):
			if a.get_pixel(x,y) != b.get_pixel(x,y): result += 1
	return result
func frame_image() -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	var hud = load("res://scenes/components/service_hud.tscn").instantiate()
	root.add_child(hud)
	hud.position = Vector2(10,30)
	await process_frame
	var amount = hud.get_node("Money/Amount")
	amount.set_amount(0,true)
	hud.set_frozen(true)
	print("viewport ",root.size," / ",root.get_texture().get_size())
	print("effect identities ", hud.money_wave.get_instance_id(), " ", hud.timer_wave.get_instance_id(), " actual ", hud.get_node("Timer").custom_effects[0].get_instance_id())
	var a: Image = await frame_image()
	hud.money_wave.phase += 1.5
	hud.timer_wave.phase += 1.5
	hud.orders_wave.phase += 1.5
	var b: Image = await frame_image()
	a.save_png("res://tests/wave_a.png")
	b.save_png("res://tests/wave_b.png")
	for path in ["Money","Timer","Orders/CompletedTitle"]:
		var label: Control = hud.get_node(path)
		var rect: Rect2 = label.get_global_rect()
		var pixel_scale := root.get_texture().get_size() / Vector2(root.size)
		var pixels := changed(a,b,Rect2(rect.position * pixel_scale,rect.size * pixel_scale))
		print(path," changed pixels: ",pixels)
		assert(pixels > 10,"actual rendered glyphs wave: " + path)
	var char0 := CharFXTransform.new()
	var char1 := CharFXTransform.new()
	char0.relative_index = 0
	char1.relative_index = 1
	hud.money_wave._process_custom_fx(char0)
	hud.money_wave._process_custom_fx(char1)
	assert(not is_equal_approx(char0.offset.y,char1.offset.y), "letters have different phases")
	hud.set_frozen(false)
	amount.set_amount(15)
	var money_phase: float = hud.money_wave.phase
	var timer_phase: float = hud.timer_wave.phase
	await create_timer(.2).timeout
	assert(hud.money_wave.phase == money_phase, "whole revenue wave pauses during income")
	assert(hud.timer_wave.phase > timer_phase, "time wave continues during income")
	await create_timer(.5).timeout
	assert(hud.money_wave.phase > money_phase, "revenue wave resumes after pop")
	hud.set_frozen(true)
	var phase: float = hud.timer_wave.phase
	await create_timer(.1).timeout
	assert(hud.timer_wave.phase == phase)
	print("PASS: rendered per-character wave on all HUD groups, separate glyph phases, income hold/resume, other groups keep moving, global freeze")
	quit()
