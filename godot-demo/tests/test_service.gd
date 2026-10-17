extends SceneTree
const Service = preload("res://scripts/service.gd")
var checks := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		push_error("FAIL: " + label)
		quit(1)
		assert(value, label)
	print("PASS: " + label)

func _init() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://config/balance.json"))
	cfg.seed = 7
	cfg.initial_arrival_min = 0.0
	cfg.initial_arrival_max = 0.0
	cfg.dda.enabled = false
	var s = Service.new(cfg)
	s.start()
	check(s.customers.size() == 3 and s.raw_eggs == 6 and s.warm == 0, "initial state")
	check(not s.restock(), "full supplies ignore phone")
	check(s.place_bowl() and not s.place_bowl(), "single filling slot")
	check(s.pour(0) and not s.pour(1), "one tea and pour lock")
	check(not s.discard("tea"), "pouring cannot be discarded")
	s.tick(1.21)
	check(s.bowl == "full" and not s.pour(1), "filled bowl cannot be overwritten")
	var c: Dictionary = s.customers[0]
	c.tea = 0; c.tea_done = false; c.eggs = 2; c.eggs_done = 0
	check(s.deliver(0, "tea") and s.earned == 0, "partial delivery does not pay")
	check(not s.deliver(0, "tea"), "extra tea rejected")
	check(s.cook() and not s.cook() and s.raw_eggs == 0, "batch cooking consumes six")
	check(s.restock() and not s.restock(), "restock cannot repeat")
	s.tick(1.51)
	check(s.raw_eggs == 6 and s.pot == "cooking", "restock does not replace cooking")
	s.tick(6.5)
	check(s.pot == "ready", "egg cooking completes")
	s.warm = 3
	check(s.transfer() and not s.transfer(), "transfer exclusive")
	s.tick(0.41)
	check(s.warm == 6 and s.pot == "empty", "top up discards remainder")
	check(s.deliver(0, "egg") and s.earned == 0, "first egg partial")
	check(s.deliver(0, "egg") and s.earned == 24 and s.complete_count == 1, "complete order pays exactly once")
	check(not s.deliver(0, "egg"), "departed customer rejects")
	s.tick(1.3)
	c = s.customers[0]
	c.tea = 2; c.tea_done = false; c.eggs = 0; c.eggs_done = 0
	s.place_bowl(); s.pour(0); s.tick(1.21)
	check(s.deliver(0, "tea") and s.earned == 30, "wrong flavour reduces income only")
	c = s.customers[1]
	c.tea_done = false; c.eggs = 3; c.eggs_done = 0; c.value = 0; c.patience = 0.2
	check(s.deliver(1, "egg"), "partial egg accepted")
	s.tick(0.21)
	check(not c.present and s.earned == 36, "patience expiry pays partial")
	var closing = Service.new(cfg)
	closing.start()
	closing.customers[0].value = 100
	closing.left = 0.01
	closing.tick(0.02)
	check(not closing.active and closing.earned == 0 and closing.incomplete_count == 3, "closing never pays unfinished orders")
	check(not closing.place_bowl() and not closing.cook() and not closing.restock(), "all mutations locked after close")
	var again = Service.new(cfg)
	again.start()
	check(again.raw_eggs == 6 and again.warm == 0 and again.bowl == "absent" and again.pot == "empty", "next day resets stock and progress")
	print("ALL %d CHECKS PASSED" % checks)
	quit(0)
