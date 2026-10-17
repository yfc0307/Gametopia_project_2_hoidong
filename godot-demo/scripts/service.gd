extends RefCounted
## Pure gameplay state. Visuals and audio may be replaced independently.
const Difficulty = preload("res://scripts/difficulty.gd")
var difficulty: RefCounted
var configured_slots := 3
signal paid(amount: int, complete: bool)
signal restocked
signal closed
var cfg: Dictionary
var rng := RandomNumberGenerator.new()
var active := false
var left := 0.0
var earned := 0
var complete_count := 0
var incomplete_count := 0
var raw_eggs := 6
var pot := "empty"
var pot_left := 0.0
var transfer_left := 0.0
var warm := 0
var bowl := "absent"
var tea := -1
var pour_left := 0.0
var restock_left := 0.0
var customers: Array = []
var elapsed := 0.0
var multi_seconds := 0.0

func _init(config: Dictionary, profile: Dictionary = {}) -> void:
	cfg = config
	difficulty = Difficulty.new(cfg, profile)
	configured_slots = clampi(int(cfg.customer_slots), 1, mini(3, int(cfg.get("dda", {}).get("max_customers", 3))))
	if int(cfg.seed) == 0: rng.randomize()
	else: rng.seed = int(cfg.seed)

func start() -> void:
	active = true
	left = float(cfg.day_seconds)
	customers.clear()
	for i in range(configured_slots):
		var pending := make_customer()
		pending.present = float(cfg.get("initial_arrival_max", 3.2)) <= 0.0
		pending.wait = rng.randf_range(cfg.get("initial_arrival_min", 0.2), cfg.get("initial_arrival_max", 3.2))
		pending["scheduled"] = true
		customers.append(pending)

func make_customer() -> Dictionary:
	var p := rng.randf()
	var wants_tea := p >= float(cfg.egg_only_probability)
	var eggs := 0 if p < float(cfg.egg_only_probability) + float(cfg.tea_only_probability) and wants_tea else rng.randi_range(1, 3)
	var work: float = (2.0 + float(cfg.tea_seconds) if wants_tea else 0.0) + eggs * 1.0 + (1.0 if eggs > 0 else 0.0)
	var shortage := 0.0
	if eggs > warm:
		shortage = float(cfg.egg_seconds) + float(cfg.egg_transfer_seconds)
		if raw_eggs == 0: shortage += float(cfg.restock_seconds)
	var patience_budget: float = difficulty.budget(work, shortage, configured_slots) if cfg.get("dda", {}).get("enabled", true) else float(cfg.patience_seconds)
	var variation: float = cfg.get("walk_speed_variation", 0.08)
	return {"present": true, "patience_max": patience_budget, "work": work, "stock_wait": 0.0, "service_time": 0.0, "walk_speed_factor": rng.randf_range(1.0 - variation, 1.0 + variation), "tea": rng.randi_range(0, 4) if wants_tea else -1, "eggs": eggs,
		"tea_done": not wants_tea, "eggs_done": 0, "value": 0.0,
		"patience": patience_budget, "wait": 0.0, "face": rng.randi_range(0, 3), "reaction": 0.0}

func tick(delta: float) -> void:
	if not active: return
	# Closing wins a tie: no input/partial settlement at or after the deadline.
	var dt := minf(delta, left)
	left = maxf(0.0, left - dt)
	elapsed += dt
	var present := 0
	for c in customers:
		if c.present and not c.get("arriving", false): present += 1
	if present >= 2: multi_seconds += dt
	if left <= 0:
		for c in customers:
			if c.present: incomplete_count += 1
		active = false
		closed.emit()
		return
	var near_expiry := 0
	for c in customers:
		if c.present and not c.get("arriving", false) and c.patience < c.patience_max * 0.25: near_expiry += 1
	difficulty.tick(dt, present, near_expiry)
	if bowl == "pouring":
		pour_left = maxf(0, pour_left - dt)
		if pour_left <= 0: bowl = "full"
	if pot == "cooking":
		pot_left = maxf(0, pot_left - dt)
		if pot_left <= 0: pot = "ready"
	if transfer_left > 0:
		transfer_left = maxf(0, transfer_left - dt)
		if transfer_left <= 0:
			warm = int(cfg.egg_capacity)
			pot = "empty"
	if restock_left > 0:
		restock_left = maxf(0, restock_left - dt)
		if restock_left <= 0:
			raw_eggs = int(cfg.egg_capacity)
			restocked.emit()
	for i in range(customers.size()):
		var c: Dictionary = customers[i]
		if c.present:
			if c.get("arriving", false): continue
			c.service_time += dt
			if c.eggs > c.eggs_done and warm == 0: c.stock_wait += dt
			c.reaction = maxf(0, c.reaction - dt)
			c.patience = maxf(0, c.patience - dt)
			if c.patience <= 0: settle(i, false)
		else:
			if c.get("departing", false): continue
			c.wait -= dt
			if c.wait <= 0: customers[i] = make_customer()

func place_bowl() -> bool:
	if not active or bowl != "absent": return false
	bowl = "empty"
	return true

func pour(kind: int) -> bool:
	if not active or bowl != "empty": return false
	tea = kind
	bowl = "pouring"
	pour_left = float(cfg.tea_seconds)
	return true

func cook() -> bool:
	if not active or pot != "empty" or raw_eggs < int(cfg.egg_capacity) or restock_left > 0: return false
	raw_eggs -= int(cfg.egg_capacity)
	pot = "cooking"
	pot_left = float(cfg.egg_seconds)
	return true

func transfer() -> bool:
	if not active or pot != "ready" or warm >= int(cfg.egg_capacity) or transfer_left > 0: return false
	pot = "transferring"
	transfer_left = float(cfg.egg_transfer_seconds)
	return true

func restock() -> bool:
	if not active or restock_left > 0 or raw_eggs >= int(cfg.egg_capacity): return false
	restock_left = float(cfg.restock_seconds)
	return true

func accepts(index: int, item: String) -> bool:
	if not active or index < 0 or index >= customers.size(): return false
	var c: Dictionary = customers[index]
	if not c.present or c.get("arriving", false): return false
	if item == "tea": return bowl == "full" and not c.tea_done
	if item == "egg": return warm > 0 and c.eggs_done < c.eggs
	return false

func deliver(index: int, item: String) -> bool:
	if not accepts(index, item): return false
	var c: Dictionary = customers[index]
	if item == "tea":
		c.tea_done = true
		c.value += float(cfg.tea_price) * (1.0 if tea == c.tea else float(cfg.wrong_tea_multiplier))
		bowl = "absent"
		tea = -1
	else:
		warm -= 1
		c.eggs_done += 1
		c.value += float(cfg.egg_price)
	if c.tea_done and c.eggs_done >= c.eggs: settle(index, true)
	return true

func discard(item: String) -> bool:
	if not active: return false
	if item in ["tea", "empty_bowl"] and bowl in ["full", "empty"]:
		bowl = "absent"
		tea = -1
		return true
	if item == "egg" and warm > 0:
		warm -= 1
		return true
	return false

func settle(index: int, complete: bool) -> void:
	var c: Dictionary = customers[index]
	var amount := int(round(c.value))
	earned += amount
	if complete: complete_count += 1
	else: incomplete_count += 1
	c.present = false
	difficulty.observe(c, complete)
	c.wait = difficulty.interval if cfg.get("dda", {}).get("enabled", true) else float(cfg.respawn_seconds)
	paid.emit(amount, complete)
