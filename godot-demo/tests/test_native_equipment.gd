extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	await process_frame
	for path in ["Kettles/Kettle0", "EggSupply", "CookingPot", "WarmingPot", "BowlSupply", "FillingSlot", "Phone", "Trash"]:
		var equipment: Control = ui.get_node("Shop/" + path)
		assert(equipment.get_script() == null)
		var design: Control = equipment.get_node("Design")
		assert(design.scale == Vector2.ONE)
		var original: Vector2 = design.get_global_transform().get_scale()
		equipment.scale *= 1.25
		assert(design.get_global_transform().get_scale().is_equal_approx(original * 1.25))
		equipment.scale /= 1.25
	var caption: Label = ui.get_node("Shop/Trash/Design/Caption")
	var frame: Control = caption.get_node("Frame")
	var old_frame := frame.size
	caption.size += Vector2(30, 10)
	await process_frame
	assert(frame.size.is_equal_approx(old_frame + Vector2(30, 10)))
	assert(frame.anchor_right == 1.0 and frame.anchor_bottom == 1.0)
	print("NATIVE EQUIPMENT PASSED: eight script-free roots, consistent Scale, caption frame follows resize")
	quit()
