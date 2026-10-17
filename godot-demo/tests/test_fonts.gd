extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	var ui_font: Font = ui.get_theme_font("font", "Label")
	var label_font: Font = ui.get_node("Shop/Kettles/Kettle0/Design/Tag/Name").get_theme_font("font")
	assert(ui_font.resource_path.ends_with("jf-openhuninn-2.1.ttf"))
	assert(label_font.resource_path.ends_with("Iansui-Regular.ttf"))
	var missing: Array[String] = []
	for label in ui.find_children("*", "Label", true, false):
		var font: Font = label.get_theme_font("font")
		for ch in label.text:
			var cp: int = ch.unicode_at(0)
			if cp >= 0x3400 and cp <= 0x9fff and not font.has_char(cp):
				missing.append(str(label.get_path()) + ":" + ch)
	assert(missing.is_empty(), "Missing glyphs: " + str(missing))
	root.get_texture().get_image().save_png("res://tests/fonts_map.png")
	ui.set_process(true)
	ui.start_day()
	await create_timer(10.0).timeout
	ui.set_process(false)
	ui.sync_ui()
	ui.begin_drag(ui.kettle_rect(0).get_center())
	assert(ui.get_node("Shop/Effects/DragGhost/TeaName").get_theme_font("font") == label_font)
	ui.cancel_drag()
	ui.sync_ui()
	await process_frame
	root.get_texture().get_image().save_png("res://tests/fonts_shop.png")
	print("FONTS PASSED: embedded UI and world fonts, all authored Chinese labels covered, drag label font preserved")
	quit()
