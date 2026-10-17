extends SceneTree

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var page = load("res://scenes/pages/tea_shop.tscn").instantiate()
	root.add_child(page)
	var expected = ["廿\n四\n味", "五\n花\n茶", "銀\n菊\n露", "雞\n骨\n草", "夏\n枯\n草"]
	for i in range(5):
		assert(page.get_node("Kettles/Kettle%d/Design/Tag/Name" % i).text == expected[i])
	# Repacking a page mirrors editor saving: inherited child overrides must survive.
	var saved := PackedScene.new()
	assert(saved.pack(page) == OK)
	assert(ResourceSaver.save(saved, "res://tests/tea_labels_roundtrip.tscn") == OK)
	var reopened = load("res://tests/tea_labels_roundtrip.tscn").instantiate()
	root.add_child(reopened)
	for i in range(5):
		assert(reopened.get_node("Kettles/Kettle%d/Design/Tag/Name" % i).text == expected[i])
	page.queue_free()
	reopened.queue_free()
	print("TEA LABELS PASSED: all five names survive save and reload")
	quit()
