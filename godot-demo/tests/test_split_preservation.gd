extends SceneTree
func _init() -> void:
	var before: Control = load("res://tests/before_split.tscn").instantiate()
	var after: Control = load("res://main.tscn").instantiate()
	var count := 0
	for element in before.find_children("*", "Control", true, false):
		var path: String = str(before.get_path_to(element))
		if path == "Background": path = "Shop/Background"
		elif path == "Effects" or path.begins_with("Effects/"): path = "Shop/" + path
		assert(after.has_node(path), "missing authored element: " + path)
		var actual: Control = after.get_node(path)
		assert(actual.position.is_equal_approx(element.position), "position changed: " + path)
		assert(actual.size.is_equal_approx(element.size), "size changed: " + path)
		assert(actual.scale.is_equal_approx(element.scale), "scale changed: " + path)
		assert(is_equal_approx(actual.rotation, element.rotation), "rotation changed: " + path)
		if element is Label: assert(actual.text == element.text, "text changed: " + path)
		if element is TextureRect and element.texture is AtlasTexture:
			assert(actual.texture.region == element.texture.region, "texture region changed: " + path)
		count += 1
	print("SPLIT PRESERVATION PASSED: %d authored controls retain layout, labels and atlas regions" % count)
	before.free()
	after.free()
	quit(0)
