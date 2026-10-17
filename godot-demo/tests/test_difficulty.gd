extends SceneTree
const DDA = preload("res://scripts/difficulty.gd")
const Service = preload("res://scripts/service.gd")
func sample(spare: float, complete: bool = true) -> Dictionary:
	return {"patience_max": 60.0, "patience": spare * 60.0, "work": 7.0, "service_time": 12.0, "stock_wait": 2.0}
func window(dda, spare: float, complete: bool = true) -> void:
	for i in range(8): dda.observe(sample(spare, complete), complete)
	dda.tick(31.0, 1, 0)
func _init() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/balance.json"))
	var d = DDA.new(cfg)
	window(d, 0.9)
	assert(is_equal_approx(d.interval, 1.2), "single easy window must not immediately change difficulty")
	window(d, 0.9)
	assert(d.interval < 1.2 and d.patience == 60.0, "interval changes first")
	var stable_interval: float = d.interval
	window(d, 0.5)
	assert(d.interval == stable_interval, "target region holds")
	var before: float = d.interval
	window(d, 0.0, false)
	window(d, 0.0, false)
	assert(d.interval > before and d.patience == 60.0)
	for i in range(70): window(d, 0.0, false)
	assert(d.interval <= cfg.dda.interval_max and d.patience <= cfg.dda.patience_max)
	for i in range(140): window(d, 0.95)
	assert(d.interval >= cfg.dda.interval_min and d.patience >= cfg.dda.patience_min)
	d.protect_after_upgrade(180.0)
	before = d.patience
	window(d, 0.95)
	window(d, 0.95)
	assert(d.patience == before, "upgrade protection")
	var restored = DDA.new(cfg, d.snapshot())
	assert(restored.interval == d.interval and restored.patience == d.patience)
	var s = Service.new(cfg)
	s.rng.seed = 42
	s.start()
	assert(s.customers.size() == 3)
	var delays: Array = []
	for c in s.customers:
		assert(not c.present and c.wait >= 0.2 and c.wait <= 3.2)
		assert(c.walk_speed_factor >= 0.92 and c.walk_speed_factor <= 1.08)
		delays.append(c.wait)
	assert(delays[0] != delays[1])
	s.tick(3.3)
	assert(s.customers[0].present)
	var existing_budget: float = s.customers[0].patience_max
	var existing_patience: float = s.customers[0].patience
	s.difficulty.patience = 48.0
	assert(s.customers[0].patience_max == existing_budget and s.customers[0].patience == existing_patience)
	s.customers[0]["arriving"] = true
	s.tick(1.0)
	assert(s.customers[0].patience == existing_patience)
	s.customers[0]["arriving"] = false
	s.tick(1.0)
	assert(is_equal_approx(s.customers[0].patience, existing_patience - 1.0))
	print("DDA PASSED: randomized start/speed, sustained windows, stable region, interval-first, hard bounds, protection, profile restore, existing order fairness")
	quit()
