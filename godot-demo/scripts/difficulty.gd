extends RefCounted
## GDD section 7. Trial tuning is separate from approved design rules.
var options: Dictionary
var interval: float
var patience: float
var samples: Array[Dictionary] = []
var elapsed := 0.0
var next_check := 0.0
var last_change := -1000.0
var last_sample_count := 0
var sample_count := 0
var trend := "stable"
var streak := 0
var changes := 0
var state := "warmup"
var protection_left := 0.0
var last_metrics: Dictionary = {}
var measured_seconds := 0.0
var low_occupancy_seconds := 0.0

func _init(config: Dictionary, profile: Dictionary = {}) -> void:
	options = config.get("dda", {})
	interval = clampf(float(profile.get("interval", config.respawn_seconds)), options.get("interval_min", 0.8), options.get("interval_max", 4.0))
	patience = clampf(float(profile.get("patience", config.patience_seconds)), options.get("patience_min", 48.0), options.get("patience_max", 78.0))
	next_check = float(options.get("warmup_seconds", 20.0))

func budget(work: float, shortage: float, slots: int) -> float:
	# Allow preparation and serial hand work for everyone already sharing the shop.
	var floor_seconds: float = work * maxi(1, slots) + shortage + float(options.get("safety_seconds", 10.0))
	return clampf(maxf(patience, floor_seconds), options.get("patience_min", 48.0), options.get("patience_max", 78.0))

func observe(customer: Dictionary, complete: bool) -> void:
	var maximum: float = customer.get("patience_max", patience)
	var spare := clampf(float(customer.patience) / maxf(1.0, maximum), 0.0, 1.0)
	samples.append({"complete": complete, "spare": spare, "urgent": complete and spare < 0.25,
		"work": customer.get("work", 1.0), "stock_wait": customer.get("stock_wait", 0.0),
		"normalized_time": maxf(0.0, float(customer.get("service_time", 0.0)) - float(customer.get("stock_wait", 0.0))) / maxf(1.0, float(customer.get("work", 1.0)))})
	sample_count += 1
	while samples.size() > int(options.get("window_orders", 8)): samples.pop_front()

func tick(dt: float, active_customers: int, near_expiry: int) -> void:
	elapsed += dt
	measured_seconds += dt
	if active_customers < 2: low_occupancy_seconds += dt
	protection_left = maxf(0.0, protection_left - dt)
	if not bool(options.get("enabled", true)): state = "disabled"; return
	if elapsed < next_check: return
	next_check = elapsed + float(options.get("evaluate_seconds", 10.0))
	var window: int = options.get("window_orders", 8)
	# Each judgement requires a fresh full window, not repeated votes from old data.
	if samples.size() < window or sample_count - last_sample_count < window: return
	last_sample_count = sample_count
	var losses := 0.0
	var urgent := 0.0
	var completed := 0.0
	var spare := 0.0
	var work := 0.0
	var shortage := 0.0
	for sample in samples:
		if sample.complete:
			completed += 1.0
			spare += sample.spare
		else: losses += 1.0
		if sample.urgent: urgent += 1.0
		work += sample.work
		shortage += sample.stock_wait
	var low_ratio := low_occupancy_seconds / maxf(1.0, measured_seconds)
	measured_seconds = 0.0
	low_occupancy_seconds = 0.0
	var loss_rate := losses / window
	var urgent_rate := urgent / maxf(1.0, completed)
	var spare_mean := spare / maxf(1.0, completed)
	last_metrics = {"loss_rate": loss_rate, "urgent_rate": urgent_rate, "spare_mean": spare_mean, "mean_work": work / window, "mean_stock_wait": shortage / window}
	var judgement := "stable"
	if loss_rate > float(options.get("loss_target", 0.05)) or urgent_rate > 0.30 or near_expiry >= 2:
		judgement = "hard"
	elif completed == window and urgent_rate < 0.15 and spare_mean > 0.60 and (active_customers < 2 or low_ratio > 0.10):
		judgement = "easy"
	state = judgement
	if judgement == "stable": trend = "stable"; streak = 0; return
	streak = streak + 1 if trend == judgement else 1
	trend = judgement
	if streak < int(options.get("sustained_windows", 2)): return
	if elapsed - last_change < float(options.get("cooldown_seconds", 30.0)): return
	var before := Vector2(interval, patience)
	if judgement == "easy" and protection_left <= 0:
		if interval > float(options.get("interval_min", 0.8)):
			interval = maxf(options.get("interval_min", 0.8), interval - float(options.get("interval_step", 0.25)))
		else: patience = maxf(options.get("patience_min", 48.0), patience - float(options.get("patience_step", 2.0)))
	elif judgement == "hard":
		if interval < float(options.get("interval_max", 4.0)):
			interval = minf(options.get("interval_max", 4.0), interval + float(options.get("interval_step", 0.25)))
		else: patience = minf(options.get("patience_max", 78.0), patience + float(options.get("patience_step", 2.0)))
	if not before.is_equal_approx(Vector2(interval, patience)):
		last_change = elapsed
		changes += 1
		streak = 0
		print("DDA ", judgement, " interval=", interval, " new_patience=", patience, " metrics=", last_metrics)

func protect_after_upgrade(seconds: float = 180.0) -> void:
	protection_left = maxf(protection_left, seconds)

func snapshot() -> Dictionary:
	return {"interval": interval, "patience": patience}
