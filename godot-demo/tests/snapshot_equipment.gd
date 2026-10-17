extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.set_process(false)
	await process_frame
	await process_frame
	var result := {}
	for control in ui.get_node("Shop").find_children("*", "Control", true, false):
		var path: String = str(ui.get_path_to(control))
		if path.ends_with("/Design"): continue
		path = path.replace("/Design/", "/")
		var t: Transform2D = control.get_global_transform()
		result[path] = [t.x.x, t.x.y, t.y.x, t.y.y, t.origin.x, t.origin.y, control.size.x, control.size.y]
	var file = FileAccess.open("res://tests/equipment_snapshot.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	print("EQUIPMENT SNAPSHOT ", result.size())
	quit()
