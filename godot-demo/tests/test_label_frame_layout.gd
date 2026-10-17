extends SceneTree
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var files: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/label_fix_files.json"))
	var count := 0
	for filename in files:
		if filename.ends_with("equipment_label_frame.tscn") or not filename.ends_with(".tscn"): continue
		var page = load("res://"+filename).instantiate()
		root.add_child(page)
		await process_frame
		for frame in page.find_children("Frame", "NinePatchRect", true, false):
			var label: Control = frame.get_parent()
			assert(frame.size.is_equal_approx(label.size+Vector2(18,8)))
			var original: Vector2 = label.position
			label.position += Vector2(31,17); label.size += Vector2(45,12)
			await process_frame
			await process_frame
			assert(label.position.is_equal_approx(original+Vector2(31,17)), "must preserve label edit")
			assert(frame.position == Vector2(-9,-4) and frame.size.is_equal_approx(label.size+Vector2(18,8)), "follow label resize")
			page.scale = Vector2(.8,.8)
			assert(frame.get_global_transform().get_scale().is_equal_approx(label.get_global_transform().get_scale()), "one inherited scale")
			count += 1
		page.queue_free()
	print("PASS: ",count," equipment frames follow moved/resized labels, inherit one scale, preserve manual positions")
	quit()

