extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	await process_frame
	await process_frame
	var data := {}
	for path in ["Kettles/Kettle0", "Kettles/Kettle1", "Kettles/Kettle2", "Kettles/Kettle3", "Kettles/Kettle4", "EggSupply", "CookingPot", "WarmingPot", "BowlSupply", "FillingSlot", "Phone", "Trash"]:
		var equipment: Control = ui.get_node("Shop/" + path)
		var design: Control = equipment.get_node("Design")
		data[path] = {"size": [design.size.x, design.size.y], "scale": [equipment.scale.x * design.scale.x, equipment.scale.y * design.scale.y], "position": [equipment.position.x, equipment.position.y]}
	var file = FileAccess.open("res://tests/equipment_bases.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	print("BASES SNAPSHOT PASSED")
	quit()
