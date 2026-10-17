extends SceneTree
func _init() -> void:call_deferred("run")
func run() -> void:
	var effect=load("res://scenes/components/window_sunlight.tscn").instantiate()
	var shade=effect.get_node("CloudShade");shade.owner=null;effect.remove_child(shade)
	root.add_child(effect)
	for i in range(8):effect._process(.016)
	assert(not effect.initialized,"stale editor instance must wait without errors")
	effect.add_child(shade);effect._process(.016)
	assert(effect.initialized,"initialize when saved child is available")
	print("PASS: missing CloudShade during editor reload is safe; resumes after child restored")
	quit()
