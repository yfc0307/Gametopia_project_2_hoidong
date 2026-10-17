extends "res://scripts/service.gd"
var upgrades: Array = []
var jelly := 0
var siumai := 0
var raw_fish := 0
var lanes: Array = [[], []]
var skewer_count := -1
var skewer_flavour := -1
var fish_pending := 0
var fish_step_left := 0.0
var fish_idle_left := 0.0
var fish_return_left := 0.0
var fish_in_machine := false
var auto_slots: Array = []
var auto_selected := -1

func _init(config: Dictionary, profile: Dictionary = {}, purchased: Array = []) -> void:
	super(config, profile)
	upgrades = purchased.duplicate()
	if has_upgrade("egg_fast"): cfg = cfg.duplicate(true); cfg.egg_seconds = float(cfg.upgrade_rules.egg_fast_seconds)
	jelly = 4 if has_upgrade("jelly") else 0
	siumai = 6 if has_upgrade("siumai") else 0
	raw_fish = 12 if has_upgrade("fish") else 0
	for i in range(5): auto_slots.append({"state": "pouring", "left": float(cfg.tea_seconds)})

func has_upgrade(key: String) -> bool:
	return key in upgrades

func make_customer() -> Dictionary:
	var c: Dictionary = super.make_customer()
	c["jelly"] = false; c["jelly_done"] = true
	c["siumai"] = 0; c["siumai_done"] = 0
	c["fish"] = -1; c["fish_done"] = true
	if not (has_upgrade("jelly") or has_upgrade("siumai") or has_upgrade("fish")): return c
	var choices: Array = ["tea", "egg"]
	for key in ["jelly", "siumai", "fish"]:
		if has_upgrade(key): choices.append(key)
	var selected: Array = []
	for i in range(rng.randi_range(1, mini(3, choices.size()))):
		var index := rng.randi_range(0, choices.size() - 1)
		selected.append(choices[index]); choices.remove_at(index)
	c.tea = rng.randi_range(0, 4) if "tea" in selected else -1
	c.tea_done = c.tea < 0
	c.eggs = rng.randi_range(1, 3) if "egg" in selected else 0
	c.jelly = "jelly" in selected; c.jelly_done = not c.jelly
	c.siumai = rng.randi_range(1, 3) if "siumai" in selected else 0
	c.fish = rng.randi_range(0, 1) if "fish" in selected else -1
	c.fish_done = c.fish < 0
	c.work = (3.2 if c.tea >= 0 else 0.0) + c.eggs + (1.0 if c.jelly else 0.0) + c.siumai + (5.0 if c.fish >= 0 else 0.0)
	var shortage: float = (float(cfg.egg_seconds) if c.eggs > warm else 0.0) + (float(cfg.upgrade_rules.fish_cook_seconds) if c.fish >= 0 else 0.0)
	if cfg.get("dda", {}).get("enabled", true):
		c.patience_max = difficulty.budget(c.work, shortage, configured_slots)
		c.patience = c.patience_max
	return c

func tick(delta: float) -> void:
	if not active: return
	var dt := minf(delta, left)
	var was_returning := fish_return_left > 0
	var was_restocking := restock_left > 0
	super.tick(delta)
	if not active: return
	if was_restocking and restock_left <= 0:
		if has_upgrade("jelly"): jelly = 4
		if has_upgrade("siumai"): siumai = 6
		if has_upgrade("fish"): raw_fish = 12
	if has_upgrade("auto_tea"):
		for slot in auto_slots:
			if slot.state == "pouring":
				slot.left = maxf(0.0, slot.left - dt)
				if slot.left <= 0: slot.state = "full"
	for lane in lanes:
		for i in range(lane.size()): lane[i] = maxf(0.0, float(lane[i]) - dt)
	if fish_pending > 0:
		fish_step_left -= dt
		while fish_step_left <= 0 and fish_pending > 0:
			skewer_count += 1; fish_pending -= 1; fish_step_left += float(cfg.upgrade_rules.fish_spear_seconds)
		if fish_pending == 0:
			fish_idle_left = float(cfg.upgrade_rules.fish_idle_seconds) if skewer_count < 3 else 0.0
	elif fish_in_machine and fish_return_left <= 0:
		fish_idle_left -= dt
		if fish_idle_left <= 0: fish_return_left = float(cfg.upgrade_rules.fish_return_seconds)
	if was_returning:
		fish_return_left = maxf(0.0, fish_return_left - dt)
		if fish_return_left <= 0: fish_in_machine = false

func restock() -> bool:
	if not active or restock_left > 0: return false
	if raw_eggs >= int(cfg.egg_capacity) and (not has_upgrade("jelly") or jelly == 4) and (not has_upgrade("siumai") or siumai == 6) and (not has_upgrade("fish") or raw_fish == 12): return false
	restock_left = float(cfg.restock_seconds)
	return true

func pickup_auto(kind: int) -> bool:
	if not active or not has_upgrade("auto_tea") or bowl != "absent" or kind < 0 or kind >= 5: return false
	if auto_slots[kind].state != "full": return false
	auto_selected = kind; auto_slots[kind].state = "held"
	bowl = "full"; tea = kind
	return true

func return_auto() -> void:
	if auto_selected >= 0 and bowl == "full":
		auto_slots[auto_selected].state = "full"
		bowl = "absent"; tea = -1

func refill_auto() -> void:
	if auto_selected >= 0:
		auto_slots[auto_selected] = {"state": "pouring", "left": float(cfg.tea_seconds)}

func place_bowl() -> bool:
	return false if has_upgrade("auto_tea") else super.place_bowl()

func pour(kind: int) -> bool:
	return false if has_upgrade("auto_tea") else super.pour(kind)

func add_fish(lane: int) -> bool:
	if not active or not has_upgrade("fish") or restock_left > 0 or raw_fish <= 0 or lane < 0 or lane > 1: return false
	var count := mini(raw_fish, 6 - lanes[lane].size())
	if not has_upgrade("fish_fast"): count = mini(2, count)
	if count <= 0: return false
	for i in range(count): lanes[lane].append(float(cfg.upgrade_rules.fish_cook_seconds))
	raw_fish -= count
	return true

func place_skewer() -> bool:
	if not active or not has_upgrade("fish") or skewer_count >= 0: return false
	skewer_count = 0; skewer_flavour = -1
	return true

func spear_fish(lane: int, index: int) -> bool:
	if not active or skewer_count < 0 or skewer_count + fish_pending >= 3 or fish_return_left > 0: return false
	if lane < 0 or lane > 1 or index < 0 or index >= lanes[lane].size() or lanes[lane][index] > 0: return false
	if skewer_flavour >= 0 and skewer_flavour != lane: return false
	lanes[lane].remove_at(index) # Reserve immediately; repeated clicks cannot consume the same ball twice.
	skewer_flavour = lane; fish_pending += 1
	if fish_pending == 1: fish_step_left = float(cfg.upgrade_rules.fish_spear_seconds)
	fish_in_machine = true; fish_idle_left = float(cfg.upgrade_rules.fish_idle_seconds)
	return true

func accepts(index: int, item: String) -> bool:
	if not active or index < 0 or index >= customers.size(): return false
	var c: Dictionary = customers[index]
	if not c.present or c.get("arriving", false): return false
	match item:
		"jelly": return c.jelly and not c.jelly_done and jelly > 0 and restock_left <= 0
		"siumai": return c.siumai_done < c.siumai and siumai > 0 and restock_left <= 0
		"fish": return c.fish >= 0 and not c.fish_done and skewer_count > 0 and fish_pending == 0 and not fish_in_machine
	return super.accepts(index, item)

func deliver(index: int, item: String) -> bool:
	if item in ["tea", "egg"]:
		var automatic := item == "tea" and has_upgrade("auto_tea")
		var ok := super.deliver(index, item)
		if ok and automatic: refill_auto()
		return ok
	if not accepts(index, item): return false
	var c: Dictionary = customers[index]
	match item:
		"jelly": jelly -= 1; c.jelly_done = true; c.value += float(cfg.get("jelly_price", 18))
		"siumai": siumai -= 1; c.siumai_done += 1; c.value += float(cfg.get("siumai_price", 5))
		"fish":
			c.fish_done = true
			c.value += float(cfg.get("fish_price", 12)) * skewer_count / 3.0 * (1.0 if c.fish == skewer_flavour else float(cfg.wrong_tea_multiplier))
			skewer_count = -1; skewer_flavour = -1
	if c.tea_done and c.eggs_done >= c.eggs: settle(index, true)
	return true

func settle(index: int, complete: bool) -> void:
	var c: Dictionary = customers[index]
	if complete and (not c.get("jelly_done", true) or c.get("siumai_done", 0) < c.get("siumai", 0) or not c.get("fish_done", true)): return
	super.settle(index, complete)

func discard(item: String) -> bool:
	if not active: return false
	match item:
		"jelly":
			if jelly > 0 and restock_left <= 0: jelly -= 1; return true
		"siumai":
			if siumai > 0 and restock_left <= 0: siumai -= 1; return true
		"fish", "empty_skewer":
			if skewer_count >= 0 and fish_pending == 0 and not fish_in_machine:
				skewer_count = -1; skewer_flavour = -1; return true
		"tea":
			var ok := super.discard(item)
			if ok and has_upgrade("auto_tea"): refill_auto()
			return ok
	return super.discard(item)
