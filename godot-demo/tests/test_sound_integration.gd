extends SceneTree
## Tests the native sound studio with synthetic microphone frames, without
## reading or changing a player's save or personal recordings.

class FakeRecorder extends "res://scripts/sound_bank.gd":
	var calls: Array[String] = []
	var stopped := 0
	var cancelled := 0
	var fail_start := false
	var fail_save := false
	var silent_take := false
	func play(id: String, original: bool = false) -> void:
		calls.append(id)
		super.play(id, original)
	func stop_playback() -> void:
		stopped += 1
		super.stop_playback()
	func cancel_recording() -> void:
		cancelled += 1
		super.cancel_recording()
	func get_devices() -> PackedStringArray:
		return PackedStringArray(["Default", "Synthetic test microphone"])
	func save_custom(id: String, stream: AudioStreamWAV) -> Error:
		if fail_save: return ERR_CANT_CREATE
		return super.save_custom(id, stream)
	func start_recording(_device: String = "Default") -> bool:
		if fail_start:
			last_recording_error = "The test microphone was disconnected."
			return false
		stop_playback()
		is_recording = true
		recording_seconds = 0.0
		return true
	func _process(delta: float) -> void:
		if is_recording:
			recording_seconds = minf(MAX_RECORDING_SECONDS, recording_seconds + delta)
	func finish_recording() -> Dictionary:
		is_recording = false
		var frames := PackedVector2Array()
		frames.resize(22050)
		if not silent_take:
			for i in range(8820, 13230):
				var sample := sin(TAU * 617.0 * float(i) / 22050.0) * 0.32
				frames[i] = Vector2(sample, sample)
		return prepare_recording(frames, 22050)

var ui: Control
var bank: FakeRecorder
var studio: Control
var checks := 0
var failures := 0
var fixture_dir := ""
var progress_bytes := PackedByteArray()
var authored: Dictionary = {}
var events_seen: Dictionary = {}

func _init() -> void:
	run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + label)

func settle() -> void:
	for i in range(3):
		await process_frame

func _want_capture() -> bool:
	return "--capture-sound-pages" in OS.get_cmdline_user_args()

func capture(tag: String) -> void:
	if not _want_capture(): return
	if tag == "map": await create_timer(0.8).timeout
	await settle()
	await RenderingServer.frame_post_draw
	var suffix := "_small" if "--small-sound" in OS.get_cmdline_user_args() else ""
	root.get_texture().get_image().save_png("res://tests/artifacts/sound_" + tag + suffix + ".png")

func find_button(scope: Node, text: String) -> Button:
	for button in scope.find_children("*", "Button", true, false):
		if button.text == text: return button
	return null

func click_label(text: String) -> void:
	var button := find_button(studio, text)
	check(button != null, "Studio has button: " + text)
	if button != null:
		check(not button.disabled and button.is_visible_in_tree(), "Button available: " + text)
		button.pressed.emit()

func collect_layout() -> Dictionary:
	var result := {}
	for path in ["Shop/Kettles", "Shop/EggSupply", "Shop/CookingPot", "Shop/WarmingPot", "Shop/BowlSupply", "Shop/FillingSlot", "Shop/Phone", "Shop/Trash", "Shop/UpgradeStations"]:
		var node: Control = ui.get_node(path)
		result[path] = [node.position, node.size, node.scale, node.rotation]
	return result

func check_layout() -> void:
	var now := collect_layout()
	for path in authored:
		check(now[path] == authored[path], "Studio preserves authored equipment: " + path)

func check_bounds() -> void:
	var bounds := root.get_visible_rect()
	for node in studio.find_children("*", "Control", true, false):
		if not node.is_visible_in_tree(): continue
		if node is Button or node is ScrollContainer:
			var clipped: Rect2 = node.get_global_rect()
			var ancestor: Node = node.get_parent()
			while ancestor != null and ancestor != studio:
				if ancestor is ScrollContainer:
					clipped = clipped.intersection(ancestor.get_global_rect())
				ancestor = ancestor.get_parent()
			check(not clipped.has_area() or bounds.grow(1.0).encloses(clipped), "Studio control fits viewport: " + str(node.name))

func begin_events() -> void:
	bank.calls.clear()

func expect_event(id: String, label: String) -> void:
	check(id in bank.calls, label + " emits " + id)
	if id in bank.calls: events_seen[id] = true

func drag_to(source: Vector2, target: Vector2, expected: String) -> void:
	ui.begin_drag(source)
	check(ui.drag == expected, "Real equipment begins " + expected + " drag")
	ui.finish_drag(target)
	check(ui.drag == "", "Drop clears held item")

func customer(index: int, tea: int = -1, eggs: int = 0) -> Dictionary:
	var c: Dictionary = ui.game.make_customer()
	c.present = true
	c["arriving"] = false
	c["departing"] = false
	c.tea = tea
	c.tea_done = tea < 0
	c.eggs = eggs
	c.eggs_done = 0
	c.jelly = false
	c.jelly_done = true
	c.siumai = 0
	c.siumai_done = 0
	c.fish = -1
	c.fish_done = true
	c.patience = 100.0
	c.patience_max = 100.0
	ui.game.customers[index] = c
	var visual = ui.get_node("Shop/WindowMask/Customers/Customer%d" % index)
	visual.reset_motion()
	visual.initialized = true
	visual.was_present = true
	visual.entering = false
	visual.departing = false
	visual.get_node("Avatar").visible = true
	visual.get_node("OrderCard").visible = true
	visual.set_process(false)
	# Arrival animation is orthogonal to audio routing; this fixture is at counter.
	c["arriving"] = false
	return c

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	if "--small-sound" in OS.get_cmdline_user_args(): root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DirAccess.make_dir_recursive_absolute("res://tests/artifacts")
	fixture_dir = "res://tests/artifacts/sound_fixture_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(fixture_dir)
	var save_path := fixture_dir.path_join("progress.json")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "money": 318, "day": 7, "upgrades": [], "dda_profile": {}, "upgrade_protection": false}))
	file.close()
	progress_bytes = FileAccess.get_file_as_bytes(save_path)
	bank = FakeRecorder.new()
	bank.storage_directory = fixture_dir.path_join("recordings")
	root.add_child(bank)
	ui = load("res://main.tscn").instantiate()
	ui.save_path = save_path
	ui.sound_bank = bank
	root.add_child(ui)
	ui.set_process(false)
	bank.set_process(false)
	await settle()
	studio = ui.get_node("SoundStudio")
	authored = collect_layout()
	check(ui.screen == "map" and ui.money == 318 and ui.day == 7, "Existing saved progress loads unchanged")
	check(ui.sound_bank == bank, "Main and studio share injectable sound service")
	check(studio.scene_file_path == "res://scenes/pages/sound_studio.tscn", "Studio is an independently editable native page")
	await capture("map")
	await test_studio()
	await test_gameplay()
	check_layout()
	bank.stop_playback()
	ui.queue_free()
	bank.queue_free()
	await settle()
	await create_timer(0.15).timeout
	_cleanup_fixture()
	print("SOUND INTEGRATION: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_studio() -> void:
	ui.get_node("Map/CustomiseSound").pressed.emit()
	await settle()
	check(ui.screen == "sound_studio" and studio.visible, "Map navigation opens sound studio")
	check(not ui.get_node("Map").visible and not ui.get_node("Shop").visible, "Studio has its own page state")
	check(not studio.current_effect.is_empty() and studio.record_state == "idle", "Initial effect is randomly selected for recording")
	check(bank.EFFECTS.size() == 21, "All 21 actual game sound events are exposed")
	check(studio.device_picker.item_count == 2, "Available microphone devices populate native selector")
	check(studio._rows.size() == bank.EFFECTS.size(), "Sidebar has one real button for every catalog sound")
	check_bounds()
	await capture("studio_idle")
	for i in range(30):
		var before: String = studio.current_effect.id
		studio._pick_another()
		check(studio.current_effect.id != before, "Pick Another does not repeat current selection")
	for effect in bank.EFFECTS:
		var row: Button = studio._rows.get(effect.id)
		check(row != null and row.get_meta("effect_id", "") == effect.id, "Native sidebar row has stable event ID: " + effect.id)
		if row != null: row.pressed.emit()
		await settle()
		check(studio.current_effect.id == effect.id, "Sidebar can select " + effect.id)
		check(not str(studio.current_effect.trigger).is_empty(), "Selected event describes real trigger: " + effect.id)
		if row != null:
			var scroller: Control = studio.get_node("Sheet/Sidebar/Scroll")
			check(scroller.get_global_rect().grow(2.0).encloses(row.get_global_rect()), "Selected sidebar sound scrolls fully into view: " + effect.id)
	studio._select_effect("tea_pour")
	var original: AudioStreamWAV = bank.get_sound("tea_pour", true)
	studio._preview_original()
	check(bank._players.any(func(p): return p.stream == original), "Original preview plays selected factory sound")
	bank.fail_start = true
	studio._begin_recording()
	check(studio.record_state == "idle" and not bank.is_recording, "Disconnected microphone stays recoverable")
	bank.fail_start = false
	bank.silent_take = true
	studio._begin_recording()
	check(studio.record_state == "recording" and bank.is_recording, "Record explicitly starts microphone")
	studio._finish_recording()
	check(studio.record_state == "idle" and not bank.has_custom("tea_pour"), "Silence is rejected without replacing sound")
	bank.silent_take = false
	studio._begin_recording()
	await capture("studio_recording")
	studio._finish_recording()
	check(studio.record_state == "review" and not bank.is_recording, "Stop exposes review and releases microphone")
	check(studio.candidate is AudioStreamWAV and studio.candidate.get_length() < 0.25, "Leading silence is trimmed from microphone take")
	check(not bank.has_custom("tea_pour"), "Review alone does not change gameplay sound")
	check_bounds()
	await capture("studio_review")
	studio._preview_candidate()
	check(bank._players.any(func(p): return p.stream == studio.candidate), "Candidate preview uses actual trimmed take")
	studio._save_recording()
	check(studio.record_state == "saved" and bank.has_custom("tea_pour"), "Save installs recording for selected event")
	check(bank.get_sound("tea_pour") != original and bank.get_sound("tea_pour", true) == original, "Custom playback preserves original preview")
	check(FileAccess.file_exists(bank.storage_directory.path_join("tea_pour.wav")), "Recorded WAV persists in isolated custom-sound storage")
	check_bounds()
	await capture("studio_saved")
	# The saved prompt must expose both actions as buttons, not only methods.
	var yes := find_button(studio, "是 · Yes")
	var no := find_button(studio, "否 · No")
	check(yes != null and no != null, "Completion asks whether to customise another sound")
	if yes != null:
		yes.pressed.emit()
		check(studio.record_state == "idle" and studio.current_effect.id != "tea_pour", "Yes begins another distinct sound")
	studio._begin_recording()
	bank.recording_seconds = bank.MAX_RECORDING_SECONDS
	studio._process(0.01)
	check(studio.record_state == "review" and not bank.is_recording, "Eight-second recording limit automatically opens review")
	studio._select_effect("phone_restock")
	check(studio.record_state == "idle" and studio.candidate == null, "Changing effect discards uncommitted take")
	studio._begin_recording()
	studio._finish_recording()
	studio._save_recording()
	check(bank.has_custom("phone_restock"), "A second event can be customised independently")
	no = find_button(studio, "否 · No")
	if no != null: no.pressed.emit()
	check(ui.screen == "map", "No returns to original map")
	check(FileAccess.get_file_as_bytes(ui.save_path) == progress_bytes and ui.money == 318 and ui.day == 7, "Recording and navigation never modify game progress")
	check_layout()
	ui.show_sound_studio()
	studio._begin_recording()
	ui.show_map()
	check(not bank.is_recording and not studio.visible, "Leaving studio cancels microphone capture")
	ui.show_sound_studio()
	studio._begin_recording()
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not bank.is_recording and studio.record_state != "recording", "Losing app focus stops recording")
	studio._begin_recording()
	var escape := InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	ui._unhandled_key_input(escape)
	check(not bank.is_recording and ui.screen == "map", "Escape closes studio and cancels capture")
	var reloaded = load("res://scripts/sound_bank.gd").new()
	reloaded.storage_directory = bank.storage_directory
	root.add_child(reloaded)
	check(reloaded.has_custom("tea_pour") and reloaded.has_custom("phone_restock"), "Both saved effects survive fresh sound-bank load")
	check(reloaded.get_sound("tea_pour").data == bank.get_sound("tea_pour").data, "Reload preserves trimmed recording samples")
	reloaded.queue_free()
	await settle()
	# A failed write must leave the working replacement intact and the take reviewable.
	ui.show_sound_studio()
	studio._select_effect("tea_pour")
	var saved_stream: AudioStreamWAV = bank.get_sound("tea_pour")
	studio._begin_recording()
	studio._finish_recording()
	bank.fail_save = true
	studio._save_recording()
	check(studio.record_state == "review" and studio.candidate != null, "Failed save retains take for retry")
	check(bank.get_sound("tea_pour") == saved_stream and not studio.status_label.text.is_empty(), "Failed save preserves active sound and explains failure")
	bank.fail_save = false
	ui.show_map()

func test_gameplay() -> void:
	begin_events()
	ui._on_action("show_help")
	expect_event("ui_click", "Existing menu action")
	ui.show_map()
	begin_events()
	ui.test_base()
	expect_event("shop_open", "Opening the existing test shop")
	check(ui.test_mode, "Gameplay regression stays in non-saving test session")
	begin_events()
	drag_to(ui.bowl_source.get_center(), Vector2(-200, -200), "new_bowl")
	expect_event("pick_up", "Taking an authored supply bowl")
	expect_event("drop_return", "Genuine invalid bowl drop")
	check("drop_valid" not in bank.calls and ui.game.bowl == "absent", "Invalid drop retains inventory and never announces acceptance")
	begin_events()
	drag_to(ui.bowl_source.get_center(), ui.fill_zone.get_center(), "new_bowl")
	expect_event("drop_valid", "Placing bowl in native filling slot")
	check(ui.game.bowl == "empty", "Production state receives the same bowl placement")
	begin_events()
	drag_to(ui.kettle_rect(0).get_center(), ui.fill_zone.get_center(), "kettle")
	expect_event("tea_pour", "Dropping kettle into empty bowl")
	check(bank._players.any(func(p): return p.stream == bank.get_sound("tea_pour")), "Real tea-pour action uses the saved microphone recording")
	check("tea_ready" not in bank.calls, "Ready cue waits for completion")
	begin_events()
	ui._process(1.21)
	expect_event("tea_ready", "Manual pouring reaches full bowl")
	begin_events()
	ui._process(0.01)
	check("tea_ready" not in bank.calls, "Ready cue plays once per completion")
	customer(0, 0)
	begin_events()
	drag_to(ui.fill_zone.get_center(), ui.customer_rect(0).get_center(), "tea")
	expect_event("order_paid", "Complete tea order")
	check(ui.game.earned == int(ui.cfg.tea_price), "Custom audio retains existing payment amount")
	begin_events()
	drag_to(ui.egg_zone.get_center(), ui.pot_zone.get_center(), "raw_eggs")
	expect_event("egg_cook", "Raw egg batch accepted by original cooker")
	begin_events()
	ui.begin_drag(ui.phone_zone.get_center())
	expect_event("phone_restock", "Successful phone call")
	check(bank._players.any(func(p): return p.stream == bank.get_sound("phone_restock")), "Real phone action uses its separate saved recording")
	begin_events()
	ui.begin_drag(ui.phone_zone.get_center())
	check("phone_restock" not in bank.calls, "Busy phone does not replay successful-restock effect")
	begin_events()
	ui._process(1.51)
	expect_event("restock_complete", "Actual replenishment finishes")
	begin_events()
	ui._process(6.6)
	expect_event("egg_ready", "Egg batch reaches cooked state")
	begin_events()
	ui.begin_drag(ui.pot_zone.get_center())
	expect_event("egg_transfer", "Cooker click starts real warming transfer")
	ui._process(0.41)
	begin_events()
	drag_to(ui.warm_zone.get_center(), ui.bin_zone.get_center(), "egg")
	expect_event("discard", "Actual cooked egg discarded")
	check(ui.game.warm == 5, "Discard cue corresponds to one inventory removal")
	var departing := customer(1, -1, 1)
	departing.patience = 0.01
	begin_events()
	ui._process(0.02)
	expect_event("customer_leave", "Customer patience expires")
	var arriving := customer(2, 1)
	arriving.present = false
	arriving.wait = 0.01
	arriving["departing"] = false
	var slot = ui.get_node("Shop/WindowMask/Customers/Customer2")
	slot.reset_motion()
	slot.initialized = true
	slot.was_present = false
	begin_events()
	ui._process(0.02)
	expect_event("customer_arrive", "New customer enters the real service roster")
	ui.test_fish()
	begin_events()
	drag_to(ui.rect_of("Shop/UpgradeStations/Fish/Raw").get_center(), ui.rect_of("Shop/UpgradeStations/Fish/Boiler/Lane0").get_center(), "raw_fish")
	expect_event("fish_cook", "Raw fish accepted by boiling lane")
	ui._process(6.01)
	drag_to(ui.rect_of("Shop/UpgradeStations/Fish/Sticks").get_center(), ui.rect_of("Shop/UpgradeStations/Fish/Assembly").get_center(), "new_skewer")
	begin_events()
	ui.begin_drag(ui.rect_of("Shop/UpgradeStations/Fish/Boiler/Lane0/Ball0").get_center())
	expect_event("fish_spear", "Clicking a ready fish ball reserves it")
	check(ui.game.fish_pending == 1 and ui.game.lanes[0].size() == 1, "Skewer cue corresponds to a real fish reservation")
	ui._process(0.19)
	ui._process(0.36)
	begin_events()
	ui._process(0.26)
	expect_event("skewer_ready", "Partial skewer finishes its return animation")
	begin_events()
	ui._process(0.02)
	check("skewer_ready" not in bank.calls, "Skewer ready does not repeat while idle")
	# Muting must stop voices already playing as well as suppress future events.
	ui.sound("tea_pour")
	var stopped_before: int = bank.stopped
	ui.toggle_sound()
	check(ui.muted and bank.stopped > stopped_before, "Existing sound button immediately stops active audio")
	check(bank._players.all(func(p): return not p.playing), "No game voice remains playing after mute")
	begin_events()
	ui.sound("phone_restock")
	check(bank.calls.is_empty(), "Muted gameplay never routes sound to player")
	ui.toggle_sound()
	begin_events()
	ui.sound("phone_restock")
	check("phone_restock" in bank.calls, "Unmute restores custom playback")
	# Closing boundary still wins: no ready cue can occur after the day ends.
	ui.game.bowl = "pouring"
	ui.game.pour_left = 0.001
	ui.game.left = 0.01
	begin_events()
	ui._process(0.02)
	expect_event("day_closed", "Actual business timer expires")
	check("tea_ready" not in bank.calls and ui.screen == "closing", "Closing suppresses post-deadline production cues")
	await create_timer(0.75).timeout
	ui.show_map()
	ui.show_upgrades()
	ui.money = 1000
	begin_events()
	ui.purchase_upgrade("jelly")
	expect_event("upgrade_buy", "Existing paid upgrade succeeds")
	check(ui.money == 1000 - int(ui.cfg.upgrade_prices.jelly), "Sound hook preserves existing upgrade price")
	for effect in bank.EFFECTS:
		check(events_seen.has(effect.id), "Catalog entry has exercised actual transition: " + effect.id)
	ui.show_map()

func _cleanup_fixture() -> void:
	# Only remove files created in this unique fixture, never user:// content.
	var recording_path := fixture_dir.path_join("recordings")
	if DirAccess.dir_exists_absolute(recording_path):
		for filename in DirAccess.get_files_at(recording_path):
			DirAccess.remove_absolute(recording_path.path_join(filename))
		DirAccess.remove_absolute(recording_path)
	DirAccess.remove_absolute(fixture_dir.path_join("progress.json"))
	DirAccess.remove_absolute(fixture_dir)
