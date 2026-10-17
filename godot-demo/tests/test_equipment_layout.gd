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
		var design: Control = equipment.get_node("Design")
		var original_size := equipment.size
		var original_position := equipment.position
		var original_scale := equipment.scale
		var child: Control = design.get_child(0)
		var child_position := child.position
		equipment.size = original_size * 1.25
		assert(design.scale.is_equal_approx(Vector2(1.25, 1.25)), path + " size scales whole layout")
		assert(child.position.is_equal_approx(child_position), path + " keeps authored inner positions")
		equipment.position += Vector2(20, 10)
		assert(equipment.get_global_rect().size.is_equal_approx(original_size * 1.25 * equipment.get_global_transform().get_scale()))
		equipment.scale = original_scale * 1.1
		assert(design.get_global_transform().get_scale().is_equal_approx(equipment.get_global_transform().get_scale() * 1.25))
		equipment.size = original_size
		equipment.position = original_position
		equipment.scale = original_scale
		assert(design.scale.is_equal_approx(Vector2.ONE))
	print("EQUIPMENT LAYOUT PASSED: eight equipment roots resize/move/scale consistently without rewriting authored children")
	quit()
