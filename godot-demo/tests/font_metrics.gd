extends SceneTree
func _init() -> void:
	var scene = load("res://scenes/pages/tea_shop.tscn").instantiate()
	var label = scene.get_node("Kettles/Kettle0/Tag/Name")
	print("LABEL_METRICS ", label.text.to_utf8_buffer(), " lines=", label.get_line_count(), " line_spacing=",label.get_theme_constant("line_spacing"), " paragraph=",label.get_theme_constant("paragraph_spacing"), " font=",label.get_theme_font_size("font_size"))
	scene.free()
	quit()
