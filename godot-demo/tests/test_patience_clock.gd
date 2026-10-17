extends SceneTree
var ui
var started: int
func _init() -> void:
	call_deferred("run")
func run() -> void:
	ui = load("res://main.tscn").instantiate()
	root.add_child(ui)
	ui.start_day()
	started = Time.get_ticks_msec()
	var initial: float = ui.game.customers[0].patience
	await create_timer(5.0).timeout
	var wall_seconds := (Time.get_ticks_msec() - started) / 1000.0
	var remaining: float = ui.game.customers[0].patience
	print("PATIENCE CLOCK: config=", ui.cfg.patience_seconds, " initial=", initial, " remaining=", remaining, " real seconds=", wall_seconds, " elapsed game seconds=", ui.game.elapsed, " time_scale=", Engine.time_scale)
	assert(initial == 60.0)
	assert(abs((initial - remaining) - wall_seconds) < 0.5)
	quit()
