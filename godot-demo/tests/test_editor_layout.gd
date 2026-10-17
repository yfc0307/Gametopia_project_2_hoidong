extends SceneTree
func _init() -> void:
	call_deferred("run")

func run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	var preview: Control = scene.instantiate()
	# Disable the controller: authored content must exist with no runtime setup.
	preview.set_script(null)
	root.add_child(preview)
	assert(preview.get_node("Shop").visible)
	assert(not preview.get_node("Map").visible)
	assert(preview.get_node("Shop/CookingPot/Art") is TextureRect)
	assert(preview.get_node("Shop/Kettles/Kettle4/Art") is TextureRect)
	assert(preview.get_node("Shop/Customers/Customer2/OrderCard/Tea") is Label)
	assert(preview.get_node("Map/Start") is Button)
	assert(preview.get_node("Summary/Receipt/Total") is Label)
	assert(preview.get_node("Shop").scene_file_path == "res://scenes/pages/tea_shop.tscn")
	assert(preview.get_node("Shop/Kettles/Kettle0").scene_file_path == "res://scenes/components/kettle.tscn")
	assert(preview.get_node("Shop/Customers/Customer0").scene_file_path == "res://scenes/components/customer_order.tscn")
	# Authors now edit the page directly; its equipment instance positions persist.
	var shop: Control = load("res://scenes/pages/tea_shop.tscn").instantiate()
	var original: Vector2 = shop.get_node("CookingPot").position
	shop.get_node("CookingPot").position += Vector2(20, -10)
	var edited := PackedScene.new()
	assert(edited.pack(shop) == OK)
	var reloaded: Control = edited.instantiate()
	assert(reloaded.get_node("CookingPot").position.is_equal_approx(original + Vector2(20, -10)))
	reloaded.free()
	shop.free()
	for path in ["tea_shop", "level_select", "settlement", "instructions", "upgrades", "pause_menu"]:
		var page: Control = load("res://scenes/pages/%s.tscn" % path).instantiate()
		assert(page.visible and page.get_child_count() > 0, "independent page preview")
		page.free()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("res://tests/editor_preview.png")
	print("EDITOR LAYOUT PASSED: authored elements visible without controller, native textures/labels/buttons present, manual position survives PackedScene save/reload")
	preview.queue_free()
	await process_frame
	quit(0)
