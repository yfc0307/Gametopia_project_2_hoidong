extends Control
const CUSTOMER_PORTRAITS = [preload("res://assets/customers/granny.png"), preload("res://assets/customers/student.png"), preload("res://assets/customers/office.png"), preload("res://assets/customers/worker.png")]
const Service = preload("res://scripts/upgraded_service.gd")
const TEAS = ["廿四味", "五花茶", "銀菊露", "雞骨草", "夏枯草"]
const INK = Color("344f48")
const PAPER = Color("fff8e8")
const JADE = Color("52796b")
const RUST = Color("b36a4d")
var cfg: Dictionary
var game: RefCounted
var screen := "map"
var dda_profile: Dictionary = {}
const UPGRADE_IDS = ["egg_fast", "auto_tea", "jelly", "siumai", "fish", "fish_fast"]
var owned_upgrades: Array = []
var test_mode := false
var upgrade_protection := false
var money := 0
var day := 1
var paused := false
var drag := ""
var drag_tea := -1
var drag_origin := Vector2.ZERO
var pointer := Vector2.ZERO
var return_pos := Vector2.ZERO
var drag_visual_pos := Vector2.ZERO
@export_range(4.0, 30.0, 1.0) var drag_follow_rate := 16.0
@export_range(4.0, 30.0, 1.0) var return_follow_rate := 14.0
var return_item := ""
var return_time := 0.0
var toast := ""
var toast_left := 0.0
var quip := ""
var quip_left := 0.0
var payout := ""
var payout_left := 0.0
var bin_flash := 0.0
var font: Font
var bg: Texture2D
var atlas: Texture2D
var buttons: Array[Button] = []
var save_path := "user://hoidong_progress_v1.json"
var save_error := ""
@onready var quip_label: Label = $Shop.find_child("Quip", true, false) as Label
var muted := false
var audio: AudioStreamPlayer

# Layout is authored in scenes/pages and scenes/components. These getters never overwrite node transforms.
var egg_zone: Rect2:
	get: return rect_of("Shop/EggSupply")
var pot_zone: Rect2:
	get: return rect_of("Shop/CookingPot")
var warm_zone: Rect2:
	get: return rect_of("Shop/WarmingPot")
var bowl_source: Rect2:
	get: return rect_of("Shop/BowlSupply")
var fill_zone: Rect2:
	get: return rect_of("Shop/FillingSlot")
var phone_zone: Rect2:
	get: return rect_of("Shop/Phone")
var bin_zone: Rect2:
	get: return rect_of("Shop/Trash")

func rect_of(path: String) -> Rect2:
	return get_global_transform().affine_inverse() * (get_node(path) as Control).get_global_rect()

func kettle_rect(i: int) -> Rect2:
	return rect_of("Shop/Kettles/Kettle%d" % i)

func customer_rect(i: int) -> Rect2:
	return rect_of("Shop/WindowMask/Customers/Customer%d" % i)

func _ready() -> void:
	cfg = JSON.parse_string(FileAccess.get_file_as_string("res://config/balance.json"))
	audio = $Audio
	for b in find_children("*", "Button", true, false):
		if b.has_meta("action"): b.pressed.connect(_on_action.bind(str(b.get_meta("action"))))
	load_progress()
	show_map()
	if "--capture-map" in OS.get_cmdline_user_args(): capture.call_deferred("map")
	if "--capture-shop" in OS.get_cmdline_user_args():
		start_day()
		capture.call_deferred("shop")

func _on_action(action: String) -> void:
	sound("ui_click")
	call(action)

func capture(tag: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tests/" + tag + ".png")
	get_tree().quit()

func show_map() -> void:
	if test_mode:
		game = null
		test_mode = false
	screen = "map"
	paused = false
	cancel_drag()
	sync_ui()

func show_help() -> void:
	screen = "help"
	sync_ui()

func show_upgrades() -> void:
	screen = "upgrades"
	sync_ui()

func toggle_sound() -> void:
	muted = not muted
	sync_ui()

func start_day() -> void:
	if test_mode: game = null
	test_mode = false
	start_session(owned_upgrades)

func start_session(keys: Array) -> void:
	screen = "shop"
	paused = false
	cancel_drag()
	if game != null and not test_mode: dda_profile = game.difficulty.snapshot()
	game = Service.new(cfg, dda_profile, keys)
	if upgrade_protection and not test_mode:
		game.difficulty.protect_after_upgrade(float(cfg.day_seconds))
		upgrade_protection = false
	game.paid.connect(on_paid)
	game.closed.connect(on_close)
	game.restocked.connect(func(): sound("restock_complete"))
	for i in range(int(cfg.customer_slots)):
		get_node("Shop/WindowMask/Customers/Customer%d" % i).reset_motion()
	var traffic = $Shop/WindowMask.get_node_or_null("TramTraffic")
	if traffic: traffic.reset_traffic()
	$Shop/Effects/CustomerFeedback.clear()
	$Shop/HUD/Money/Amount.set_amount(0, true)
	game.start()
	toast = "拖碗 → 裝填位 → 拖水壺倒茶；拖六蛋入爐。"
	if "auto_tea" in keys: toast = "每壺前方直接取茶；交付或丟棄後才自動補碗。"
	if "fish" in keys: toast = "魚蛋入槽煮熟 → 拖竹籤到裝填位 → 點熟魚蛋 → 拖給顧客。"
	toast_left = 7.0
	sync_ui()

func toggle_pause() -> void:
	if screen != "shop": return
	paused = not paused
	if paused: cancel_drag()
	sync_ui()

func on_paid(amount: int, complete: bool) -> void:
	if not test_mode: money += amount
	payout = "+ $%d" % amount if amount > 0 else "下次再幫襯"
	payout_left = 1.5
	sound("order_paid" if complete else "customer_leave")

func on_close() -> void:
	cancel_drag()
	screen = "closing"
	sound("day_closed")
	if not test_mode:
		day += 1
		save_progress()
	get_tree().create_timer(0.7).timeout.connect(show_summary)
	sync_ui()

func show_summary() -> void:
	screen = "summary"
	sync_ui()

func _process(delta: float) -> void:
	pointer = get_local_mouse_position()
	if screen == "shop" and not paused:
		if drag != "": drag_visual_pos = drag_visual_pos.lerp(pointer, 1.0 - exp(-drag_follow_rate * delta))
		elif return_time > 0:
			return_pos = return_pos.lerp(drag_origin, 1.0 - exp(-return_follow_rate * delta))
			if return_pos.distance_to(drag_origin) < 0.8: return_time = 0.0
	if screen == "shop" and not paused:
		var was_pouring: bool = game.bowl == "pouring"
		game.tick(delta)
		if was_pouring and game.bowl == "full":
			return_item = "kettle"
			return_pos = fill_zone.get_center() + Vector2(-50, -57)
			drag_origin = rect_of("Shop/Kettles/Kettle%d/Design/Art" % game.tea).get_center()
			return_time = 1.0
	if not paused and screen != "closing":
		toast_left = maxf(0, toast_left - delta)
		quip_left = maxf(0, quip_left - delta)
		payout_left = maxf(0, payout_left - delta)
		bin_flash = maxf(0, bin_flash - delta)
		return_time = maxf(0, return_time - delta)
	sync_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == "shop" and not paused: toggle_pause()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if screen == "shop": toggle_pause()
		elif screen in ["help", "upgrades"]: show_map()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if screen != "shop" or paused or not game.active: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var pos := get_local_mouse_position()
		if event.pressed: begin_drag(pos)
		elif drag != "": finish_drag(pos)

func sync_ui() -> void:
	if not is_node_ready(): return
	for name in ["Map", "Shop", "Summary", "Help", "Upgrades"]:
		get_node(name).visible = (name.to_lower() == screen or name == "Shop" and screen == "closing")
	$Shop/WindowSunlight.set_frozen(paused or screen != "shop")
	$Shop/HUD.set_frozen(paused or screen != "shop")
	$Shop/Effects/CustomerFeedback.set_frozen(paused or screen != "shop")
	$PauseOverlay.visible = paused or screen == "closing"
	$PauseOverlay/Resume.visible = paused
	$PauseOverlay/Card/Title.text = "稍歇一陣" if paused else "收工喇！"
	$PauseOverlay/Card/Note.text = "ESC 繼續" if paused else "營業畫面已凍結"
	buttons.clear()
	for b in find_children("*", "Button", true, false):
		if b.is_visible_in_tree(): buttons.append(b)
	$SaveError.text = save_error
	$Map/StatsPanel/Stats.text = "第 %d 天 · 持有 $%d" % [day, money]
	$Map/Sound.text = "音效：關" if muted else "音效：開"
	var target := int(cfg.next_shop_target)
	$Map/ProgressPanel/Amounts.text = "$%d / $%d    還差 $%d" % [money, target, maxi(0, target - money)]
	$Map/ProgressPanel/Progress.value = 100.0 * money / target
	$Upgrades/Sheet/Money.text = "持有 $%d" % money
	sync_purchase_buttons()
	if game == null: return
	$Shop/HUD/Money/Amount.set_amount(game.earned)
	$Shop/HUD/Money/Amount.set_frozen(paused or screen != "shop")
	$Shop/HUD/Timer/Value.set_wave_text("%02d:%02d" % [int(ceil(game.left) / 60.0), int(ceil(game.left)) % 60])
	$Shop/HUD/Orders/Completed.set_wave_text(str(game.complete_count))
	$Shop/HUD/Orders/Incomplete.set_wave_text(str(game.incomplete_count))
	$Shop/EggSupply/Design/Art.visible = game.raw_eggs > 0 and game.restock_left <= 0
	$Shop/EggSupply/Design/Status.text = "生蛋 %d / 6" % game.raw_eggs if game.restock_left <= 0 else "翻轉補貨 %.1fs" % game.restock_left
	$Shop/CookingPot/Design/Status.text = {"empty": "煮爐 · 空", "cooking": "煮蛋 %.1fs" % game.pot_left, "ready": "熟蛋 · 點擊補滿", "transferring": "轉入保溫爐…"}.get(game.pot, "")
	$Shop/CookingPot/Design/Progress.visible = game.pot == "cooking"
	$Shop/CookingPot/Design/Progress.value = 100.0 * (1 - game.pot_left / float(game.cfg.egg_seconds))
	$Shop/WarmingPot/Design/Status.text = "保溫爐 %d / 6" % game.warm
	for i in range(6): get_node("Shop/WarmingPot/Design/Egg%d" % i).visible = i < game.warm
	$Shop/FillingSlot/Design/EmptyBowl.visible = game.bowl == "empty" and not item_in_transit("empty_bowl")
	$Shop/FillingSlot/Design/FullBowl.visible = game.bowl in ["full", "pouring"] and not item_in_transit("tea")
	$Shop/FillingSlot/Design/Status.text = {"absent": "裝填位", "empty": "拖水壺到碗上", "pouring": "倒茶 %.1fs" % game.pour_left, "full": TEAS[game.tea] if game.tea >= 0 else ""}.get(game.bowl, "")
	for i in range(5):
		var kettle_home_visible: bool = not (game.bowl == "pouring" and game.tea == i) and not (drag == "kettle" and drag_tea == i) and not (return_time > 0 and return_item == "kettle" and drag_tea == i)
		get_node("Shop/Kettles/Kettle%d/Design/Art" % i).visible = kettle_home_visible
		get_node("Shop/Kettles/Kettle%d/Design/Tag" % i).visible = kettle_home_visible
	for i in range(game.customers.size()):
		var c: Dictionary = game.customers[i]
		var slot := get_node("Shop/WindowMask/Customers/Customer%d" % i)
		slot.sync_presence(c.present, paused or screen != "shop", float(c.get("walk_speed_factor", 1.0)))
		c["arriving"] = slot.entering
		c["departing"] = slot.departing
		slot.get_node("Avatar").texture = CUSTOMER_PORTRAITS[int(c.face) % CUSTOMER_PORTRAITS.size()]
		slot.get_node("Avatar").modulate = Color(1, 0.85, 0.8) if c.reaction > 0 else Color.WHITE
		slot.get_node("OrderCard/Bubble/Items/TeaRow/Tea").text = "" if c.tea < 0 else ("✓ " if c.tea_done else "") + TEAS[c.tea]
		slot.get_node("OrderCard/Bubble/Items/TeaRow/TeaIcon").visible = c.tea >= 0
		slot.get_node("OrderCard/Bubble/Items/TeaRow/TeaIcon").modulate.a = 0.3 if c.tea_done else 1.0
		for egg_index in range(3):
			var egg_icon = slot.get_node("OrderCard/Bubble/Items/EggRow/EggIcon%d" % egg_index)
			egg_icon.visible = egg_index < c.eggs
			egg_icon.modulate.a = 0.25 if egg_index < c.eggs_done else 1.0
		slot.set_order_content(c.tea >= 0, c.eggs > 0)
		slot.get_node("OrderCard/PatienceColumn/Patience").text = "%.0fs" % c.patience
		slot.get_node("OrderCard/PatienceColumn/Progress").value = 100.0 * c.patience / float(c.patience_max)
	$Shop/Toast/Text.text = toast
	$Shop/Toast.visible = toast_left > 0 or (quip_left > 0 and $Shop/Toast.is_ancestor_of(quip_label))
	$Shop/Toast/Text.visible = toast_left > 0
	quip_label.text = "契媽：" + quip
	quip_label.visible = quip_left > 0
	$Shop/Payout.text = payout
	$Shop/Payout.visible = payout_left > 0
	$Summary/Receipt/Day.text = "第 %d 天 · 涼茶舖" % (day - 1)
	$Summary/Receipt/Income.text = "$ %d" % game.earned
	$Summary/Receipt/Completed.text = str(game.complete_count)
	$Summary/Receipt/Incomplete.text = str(game.incomplete_count)
	$Summary/Receipt/Total.text = "$ %d" % money
	$Summary/Receipt/Metrics.text = "多人同場 %.1f%% · 首輪觀察數據" % (100 * game.multi_seconds / maxf(0.01, game.elapsed))
	sync_upgrade_ui()
	sync_effects()

func sync_effects() -> void:
	var allowed: Array[Control] = []
	if screen == "shop" and not paused:
		if drag == "new_bowl" and game.bowl == "absent": allowed.append($Shop/FillingSlot)
		if drag == "kettle" and game.bowl == "empty": allowed.append($Shop/FillingSlot)
		if drag == "raw_eggs" and game.pot == "empty": allowed.append($Shop/CookingPot)
		if drag in ["tea", "empty_bowl", "new_bowl", "egg", "jelly", "siumai", "fish", "empty_skewer", "new_skewer"]: allowed.append($Shop/Trash)
		if drag == "raw_fish":
			for lane in range(2):
				if game.lanes[lane].size() < 6: allowed.append(get_node("Shop/UpgradeStations/Fish/Boiler/Lane%d" % lane))
		if drag == "new_skewer" and game.skewer_count < 0: allowed.append($Shop/UpgradeStations/Fish/Assembly)
		for i in range(game.customers.size()):
			if game.accepts(i, drag): allowed.append(get_node("Shop/WindowMask/Customers/Customer%d" % i))
	for h in $Shop.find_children("Highlight", "Panel", true, false):
		var equipment = h.get_parent().get_parent() if h.get_parent().name == "Design" else h.get_parent()
		h.visible = equipment in allowed or equipment == $Shop/Trash and bin_flash > 0
	var item := drag if drag != "" else return_item
	var pos: Vector2 = drag_visual_pos if drag != "" else return_pos
	var held: bool = screen == "shop" and not paused and (drag != "" or return_time > 0)
	$Shop/Effects/DragGhost.visible = held and item != "egg"
	$Shop/Effects/DragEgg.visible = held and item == "egg"
	var sources := {"new_bowl": $Shop/FillingSlot/Design/EmptyBowl, "empty_bowl": $Shop/FillingSlot/Design/EmptyBowl, "tea": $Shop/FillingSlot/Design/FullBowl, "raw_eggs": $Shop/EggSupply/Design/Art, "kettle": get_node("Shop/Kettles/Kettle%d/Design/Art" % maxi(0, drag_tea))}
	sources.merge({"jelly": $Shop/UpgradeStations/Jelly/Item0, "siumai": $Shop/UpgradeStations/Siumai/Item0, "raw_fish": $Shop/UpgradeStations/Fish/Raw/Art, "new_skewer": $Shop/UpgradeStations/Fish/Sticks/Art, "empty_skewer": $Shop/UpgradeStations/Fish/Assembly/Skewer, "fish": $Shop/UpgradeStations/Fish/Assembly/Skewer})
	if game.has_upgrade("auto_tea") and game.auto_selected >= 0:
		sources["tea"] = get_node("Shop/Kettles/Kettle%d/Design/AutoBowl/Art" % game.auto_selected)
	# Reusable shadows discover their assigned visual, including future equipment instances.
	var lifted_visual = sources.get(item) if held else null
	for shadow in get_tree().get_nodes_in_group("contact_shadows"):
		if $Shop.is_ancestor_of(shadow):
			var visual = shadow.get_target()
			shadow.set_lifted(visual == lifted_visual or (screen == "shop" and game.bowl == "pouring" and visual == get_node("Shop/Kettles/Kettle%d/Design/Art" % maxi(0, game.tea))))
	var ghost: TextureRect = $Shop/Effects/DragGhost
	ghost.get_node("TeaName").visible = item == "kettle"
	if item in sources:
		match_source_visual(ghost, sources[item], item == "kettle")
	var local_pos: Vector2 = $Shop/Effects.get_global_transform().affine_inverse() * get_global_transform() * pos
	ghost.position = local_pos - ghost.get_transform().basis_xform(ghost.size / 2)
	$Shop/Effects/DragEgg.position = local_pos - $Shop/Effects/DragEgg.size / 2
	sync_fish_ghost(item)
	var pouring: bool = screen == "shop" and game.bowl == "pouring"
	$Shop/Effects/PourKettle.visible = pouring
	$Shop/Effects/PourStream.visible = pouring
	if pouring:
		var center := fill_zone.get_center()
		$Shop/Effects/PourKettle.position = center + Vector2(-20, -100)
		match_source_visual($Shop/Effects/PourKettle, get_node("Shop/Kettles/Kettle%d/Design/Art" % game.tea), true)
		$Shop/Effects/PourKettle.rotation -= 0.45
		var stream: Line2D = $Shop/Effects/PourStream
		# Use the visible texture's spout and liquid surface, including aspect padding and rotation.
		var start: Vector2 = texture_point_global($Shop/Effects/PourKettle, Vector2(0.075, 0.215))
		var end: Vector2 = texture_point_global($Shop/FillingSlot/Design/FullBowl, Vector2(0.5, 0.34))
		stream.points = PackedVector2Array([stream.to_local(start), stream.to_local(end)])
	$Shop/Effects/FlyingEgg.visible = screen == "shop" and game.transfer_left > 0
	if game.transfer_left > 0:
		var t: float = 1 - game.transfer_left / float(cfg.egg_transfer_seconds)
		$Shop/Effects/FlyingEgg.position = pot_zone.get_center().lerp(warm_zone.get_center(), t) - Vector2(16, 16 + sin(t * PI) * 35)

# Only transient effects change transforms. Authored equipment remains untouched.
func match_source_visual(ghost: TextureRect, source: TextureRect, with_name: bool) -> void:
	ghost.texture = source.texture
	ghost.size = source.size
	ghost.stretch_mode = source.stretch_mode
	var relative: Transform2D = ghost.get_parent().get_global_transform().affine_inverse() * source.get_global_transform()
	ghost.scale = relative.get_scale()
	ghost.rotation = relative.get_rotation()
	var label: Label = ghost.get_node("TeaName")
	label.visible = with_name
	if not with_name: return
	var original: Label = source.get_parent().get_node("Tag/Name")
	var label_transform: Transform2D = source.get_global_transform().affine_inverse() * original.get_global_transform()
	label.position = label_transform.origin
	label.scale = label_transform.get_scale()
	label.rotation = label_transform.get_rotation()
	label.size = original.size
	label.text = original.text
	label.horizontal_alignment = original.horizontal_alignment
	label.vertical_alignment = original.vertical_alignment
	label.add_theme_font_override("font", original.get_theme_font("font"))
	label.add_theme_font_size_override("font_size", original.get_theme_font_size("font_size"))
	for key in ["font_color", "font_outline_color", "font_shadow_color"]:
		label.add_theme_color_override(key, original.get_theme_color(key))
	for key in ["outline_size", "line_spacing", "shadow_offset_x", "shadow_offset_y"]:
		label.add_theme_constant_override(key, original.get_theme_constant(key))

func load_progress() -> void:
	money = int(cfg.initial_money)
	if not FileAccess.file_exists(save_path): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary and data.get("version") == 1:
		money = maxi(0, int(data.get("money", 0)))
		day = maxi(1, int(data.get("day", 1)))
		if data.get("dda_profile") is Dictionary: dda_profile = data.dda_profile
		if data.get("upgrades") is Array:
			for key in data.upgrades:
				if key in UPGRADE_IDS and key not in owned_upgrades: owned_upgrades.append(key)
		upgrade_protection = bool(data.get("upgrade_protection", false))
	else: save_error = "存檔未能讀取，暫以新進度開始。"

func save_progress() -> void:
	if test_mode: return
	if game != null: dda_profile = game.difficulty.snapshot()
	var data := JSON.stringify({"version": 1, "money": money, "day": day, "dda_profile": dda_profile, "upgrades": owned_upgrades, "upgrade_protection": upgrade_protection})
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		save_error = "未能保存進度；請檢查磁碟權限。"
		return
	file.store_string(data)
	file.close()
	var err := DirAccess.rename_absolute(save_path + ".tmp", save_path)
	if err != OK: save_error = "未能保存進度。"


func begin_drag(p: Vector2) -> void:
	if begin_upgrade_drag(p):
		sync_ui()
		return
	if phone_zone.has_point(p):
		if game.restock():
			quip = ["六隻蛋都唔夠你賣？好，補貨！", "做生意手腳快，食飯記得慢！", "蛋就幫你補，錢就自己賺啦！"].pick_random()
			quip_left = 3.0
			sound("phone_restock")
		else: hint("補貨中，等一等。" if game.restock_left > 0 else "所有供應已滿。")
		return
	if pot_zone.has_point(p) and game.pot == "ready":
		if game.transfer(): sound("egg_transfer")
		else: hint("保溫爐已滿，熟蛋先留在煮爐。")
		return
	if fill_zone.has_point(p) and game.bowl == "pouring": return
	return_time = 0.0
	drag_visual_pos = p
	drag_origin = p
	if fill_zone.has_point(p) and game.bowl in ["empty", "full"]:
		drag = "tea" if game.bowl == "full" else "empty_bowl"
		drag_origin = rect_of("Shop/FillingSlot/Design/FullBowl" if drag == "tea" else "Shop/FillingSlot/Design/EmptyBowl").get_center()
	elif bowl_source.has_point(p) and not game.has_upgrade("auto_tea"):
		drag = "new_bowl"
		drag_origin = rect_of("Shop/BowlSupply/Design/Art").get_center()
	elif egg_zone.has_point(p) and game.raw_eggs > 0 and game.restock_left <= 0:
		drag = "raw_eggs"
		drag_origin = rect_of("Shop/EggSupply/Design/Art").get_center()
	elif warm_zone.has_point(p) and game.warm > 0:
		drag = "egg"
		drag_origin = warm_zone.get_center()
	else:
		for i in range(5):
			if kettle_rect(i).has_point(p) and not game.has_upgrade("auto_tea"):
				if game.bowl == "pouring" and game.tea == i: return
				drag = "kettle"
				drag_tea = i
				drag_origin = rect_of("Shop/Kettles/Kettle%d/Design/Art" % i).get_center()
				break
	if drag != "": sound("pick_up")
	sync_ui()

func valid_drop(p: Vector2) -> bool:
	if valid_upgrade_drop(p): return true
	if bin_zone.has_point(p): return drag in ["tea", "empty_bowl", "new_bowl", "egg", "jelly", "siumai", "fish", "empty_skewer", "new_skewer"]
	if drag == "new_bowl": return fill_zone.has_point(p) and game.bowl == "absent"
	if drag == "kettle": return fill_zone.has_point(p) and game.bowl == "empty"
	if drag == "raw_eggs": return pot_zone.has_point(p) and game.pot == "empty"
	for i in range(game.customers.size()):
		if customer_rect(i).has_point(p) and game.accepts(i, drag): return true
	return false

func finish_drag(p: Vector2) -> void:
	var accepted := false
	if bin_zone.has_point(p):
		accepted = game.discard(drag)
		if drag in ["new_bowl", "new_skewer"]: accepted = true
		if accepted:
			bin_flash = 0.2
			sound("discard")
	elif valid_upgrade_drop(p): accepted = finish_upgrade_drop(p)
	elif drag == "new_bowl" and fill_zone.has_point(p): accepted = game.place_bowl()
	elif drag == "kettle" and fill_zone.has_point(p):
		accepted = game.pour(drag_tea)
		if accepted: sound("tea_pour")
	elif drag == "raw_eggs" and pot_zone.has_point(p):
		accepted = game.cook()
		if accepted: sound("egg_cook")
	else:
		for i in range(game.customers.size()):
			if customer_rect(i).has_point(p):
				var slot = get_node("Shop/WindowMask/Customers/Customer%d"%i)
				var avatar: Control = slot.get_node("Avatar")
				var feedback_position := avatar.get_global_rect().position+Vector2(avatar.get_global_rect().size.x*.5,24)
				var imperfect: bool = drag == "tea" and game.customers[i].tea != game.tea
				if drag == "fish": imperfect = game.customers[i].fish != game.skewer_flavour or game.skewer_count < 3
				accepted = game.deliver(i, drag)
				$Shop/Effects/CustomerFeedback.show_result(feedback_position, (1 if imperfect else 0) if accepted else 2)
				if accepted:
					slot.play_receive_feedback()
					if imperfect: hint("這份少收一點。")
				else:
					game.customers[i].reaction = 1.5
					hint("唔係我要嗰樣呀。")
				break
	if not accepted:
		return_item = drag
		return_pos = drag_visual_pos
		return_time = 1.0
	if not accepted and drag == "tea" and game.has_upgrade("auto_tea"): game.return_auto()
	if not accepted: sound("drop_return")
	else: sound("drop_valid")
	drag = ""
	sync_ui()

func cancel_drag() -> void:
	if game != null and game.has_upgrade("auto_tea") and drag == "tea": game.return_auto()
	return_time = 0.0
	drag = ""
	return_item = ""

func hint(message: String) -> void:
	toast = message
	toast_left = 2.4

func sound(id: String) -> void:
	# Stable event IDs are the integration boundary for Jack's recording module.
	if muted: return
	var rates := {"tea_pour": 520.0, "egg_cook": 240.0, "order_paid": 880.0, "phone_restock": 660.0, "day_closed": 330.0}
	var rate: float = rates.get(id, 420.0)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	var count := 2205
	data.resize(count * 2)
	for i in range(count):
		var sample := int(sin(TAU * rate * i / 22050.0) * 1400 * (1.0 - float(i) / count))
		data.encode_s16(i * 2, sample)
	stream.data = data
	audio.stream = stream
	audio.play()

func sync_purchase_buttons() -> void:
	for key in UPGRADE_IDS:
		var button: Button = get_node("Upgrades/Sheet/Buy_" + key)
		var price: int = cfg.upgrade_prices[key]
		var locked: bool = key == "fish_fast" and "fish" not in owned_upgrades
		button.disabled = key in owned_upgrades or locked or money < price
		button.text = "已購入" if key in owned_upgrades else ("先解鎖魚蛋" if locked else "$ %d · 購買" % price)

func purchase_upgrade(key: String) -> void:
	if screen != "upgrades" or test_mode or key not in UPGRADE_IDS or key in owned_upgrades: return
	if key == "fish_fast" and "fish" not in owned_upgrades: return
	var price: int = cfg.upgrade_prices[key]
	if money < price: return
	money -= price
	owned_upgrades.append(key)
	upgrade_protection = true
	save_progress()
	sync_ui()

func start_upgrade_test(keys: Array) -> void:
	if game != null and not test_mode: dda_profile = game.difficulty.snapshot()
	test_mode = true
	start_session(keys)

func sync_upgrade_ui() -> void:
	var stations = $Shop/UpgradeStations
	stations.get_node("Jelly").visible = game.has_upgrade("jelly")
	stations.get_node("Siumai").visible = game.has_upgrade("siumai")
	stations.get_node("Fish").visible = game.has_upgrade("fish")
	stations.get_node("TestBadge").visible = test_mode
	if test_mode: $Summary/Receipt/Day.text = "升級測試 · 不保存進度"
	$Shop/BowlSupply.visible = not game.has_upgrade("auto_tea")
	$Shop/FillingSlot.visible = not game.has_upgrade("auto_tea")
	for i in range(5):
		var slot = get_node("Shop/Kettles/Kettle%d/Design/AutoBowl" % i)
		slot.visible = game.has_upgrade("auto_tea")
		slot.get_node("Art").visible = game.auto_slots[i].state != "held" and not (return_time > 0 and return_item == "tea" and game.auto_selected == i)
		slot.get_node("Art").modulate.a = 1.0 if game.auto_slots[i].state == "full" else 0.4
		slot.get_node("Status").text = "" if game.auto_slots[i].state == "full" else "自動倒茶…"
	for pair in [["Jelly", game.jelly, 4, "龜苓膏", "jelly"], ["Siumai", game.siumai, 6, "燒賣", "siumai"]]:
		var stock = stations.get_node(pair[0])
		stock.get_node("Status").text = "%s %d / %d" % [pair[3], pair[1], pair[2]] if game.restock_left <= 0 else "補貨中…"
		for i in range(pair[2]): stock.get_node("Item%d" % i).visible = i < pair[1] - (1 if item_in_transit(pair[4]) else 0) and game.restock_left <= 0
	var fish = stations.get_node("Fish")
	fish.get_node("Raw/Status").text = "生魚蛋 %d" % game.raw_fish
	fish.get_node("Raw/Art").visible = game.raw_fish > 0 and game.restock_left <= 0
	for lane in range(2):
		fish.get_node("Boiler/Lane%d/Count" % lane).text = "%d / 6" % game.lanes[lane].size()
		for i in range(6): fish.get_node("Boiler/Lane%d/Ball%d" % [lane, i]).visible = i < game.lanes[lane].size() and game.lanes[lane][i] <= 0
	var count: int = game.skewer_count
	fish.get_node("Assembly/Skewer").visible = count >= 0 and not game.fish_in_machine and not item_in_transit("fish") and not item_in_transit("empty_skewer")
	fish.get_node("Assembly/Status").text = "拖竹籤到此" if count < 0 else ("裝填中…" if game.fish_in_machine else "%s %d / 3" % ["原味" if game.skewer_flavour <= 0 else "咖喱辣", count])
	var flying: TextureRect = fish.get_node("FlyingSkewer")
	flying.visible = game.fish_in_machine
	if game.fish_in_machine:
		var lane_node: Control = fish.get_node("Boiler/Lane%d" % maxi(0, game.skewer_flavour))
		var from: Vector2 = fish.get_global_transform().affine_inverse() * lane_node.get_global_transform() * Vector2(15, -20)
		var skewer: TextureRect = fish.get_node("Assembly/Skewer")
		var destination: Transform2D = fish.get_global_transform().affine_inverse() * skewer.get_global_transform()
		var to: Vector2 = destination.origin
		flying.scale = destination.get_scale()
		flying.rotation = destination.get_rotation()
		flying.size = skewer.size
		for ball_index in range(3):
			var ball: TextureRect = fish.get_node("Assembly/Ball%d" % ball_index)
			var flight_ball: TextureRect = flying.get_node("Ball%d" % ball_index)
			flight_ball.position = skewer.get_transform().affine_inverse() * ball.position
			flight_ball.size = ball.size
			flight_ball.scale = ball.scale / skewer.scale
		flying.position = from.lerp(to, 1.0 - game.fish_return_left / float(cfg.upgrade_rules.fish_return_seconds)) if game.fish_return_left > 0 else from
	for i in range(3):
		var texture = fish.get_node("Boiler/Lane%d/Ball0" % maxi(0, game.skewer_flavour)).texture
		fish.get_node("Assembly/Ball%d" % i).texture = texture
		fish.get_node("Assembly/Ball%d" % i).visible = count > i and not game.fish_in_machine and not item_in_transit("fish")
		flying.get_node("Ball%d" % i).texture = texture
		flying.get_node("Ball%d" % i).visible = count > i
	for i in range(game.customers.size()):
		var c: Dictionary = game.customers[i]
		var slot = get_node("Shop/WindowMask/Customers/Customer%d" % i)
		slot.set_extra_order_content(c.jelly, c.siumai > 0, c.fish >= 0)
		var rows = slot.get_node("OrderCard/Bubble/Items")
		rows.get_node("JellyRow").modulate.a = 0.3 if c.jelly_done else 1.0
		for j in range(3):
			rows.get_node("SiumaiRow/Icon%d" % j).visible = j < c.siumai
			rows.get_node("SiumaiRow/Icon%d" % j).modulate.a = 0.3 if j < c.siumai_done else 1.0
		rows.get_node("FishRow/Flavour").text = "原味" if c.fish == 0 else "咖喱辣"
		rows.get_node("FishRow").modulate.a = 0.3 if c.fish_done else 1.0

func sync_fish_ghost(item: String) -> void:
	for i in range(3):
		var ball = $Shop/Effects/DragGhost.get_node("FishBall%d" % i)
		ball.visible = item == "fish" and i < game.skewer_count
		ball.texture = get_node("Shop/UpgradeStations/Fish/Boiler/Lane%d/Ball0" % maxi(0, game.skewer_flavour)).texture

func begin_upgrade_drag(p: Vector2) -> bool:
	var fish = $Shop/UpgradeStations/Fish
	if game.has_upgrade("fish"):
		for lane in range(2):
			for i in range(game.lanes[lane].size()):
				if game.lanes[lane][i] <= 0 and rect_of("Shop/UpgradeStations/Fish/Boiler/Lane%d/Ball%d" % [lane, i]).has_point(p):
					if not game.spear_fish(lane, i): hint("先放竹籤；同一籤只可裝同一口味，最多三顆。")
					return true
	var item := ""
	var source: Control
	if game.has_upgrade("auto_tea"):
		for i in range(5):
			if rect_of("Shop/Kettles/Kettle%d/Design/AutoBowl" % i).has_point(p):
				if game.pickup_auto(i):
					item = "tea"; source = get_node("Shop/Kettles/Kettle%d/Design/AutoBowl/Art" % i)
				else: hint("這碗仍在裝填，或手上已有一碗。")
				break
	if item == "":
		for entry in [["jelly", "Jelly", game.jelly], ["siumai", "Siumai", game.siumai]]:
			if game.has_upgrade(entry[0]) and rect_of("Shop/UpgradeStations/" + entry[1]).has_point(p):
				if entry[2] > 0 and game.restock_left <= 0:
					item = entry[0]; source = $Shop/UpgradeStations.get_node(entry[1] + "/Item0")
				else: hint("補貨中或已售完，打電話補貨。")
				if item == "": return true
	if item == "" and game.has_upgrade("fish"):
		if rect_of("Shop/UpgradeStations/Fish/Raw").has_point(p) and game.raw_fish > 0 and game.restock_left <= 0:
			item = "raw_fish"; source = fish.get_node("Raw/Art")
		elif rect_of("Shop/UpgradeStations/Fish/Sticks").has_point(p):
			item = "new_skewer"; source = fish.get_node("Sticks/Art")
		elif rect_of("Shop/UpgradeStations/Fish/Assembly").has_point(p) and game.skewer_count >= 0:
			if game.fish_in_machine: hint("等竹籤返回裝填位。"); return true
			item = "fish" if game.skewer_count > 0 else "empty_skewer"; source = fish.get_node("Assembly/Skewer")
	if item == "": return false
	return_time = 0.0; drag_visual_pos = p; drag = item
	drag_origin = get_global_transform().affine_inverse() * source.get_global_rect().get_center()
	sound("pick_up")
	return true

func valid_upgrade_drop(p: Vector2) -> bool:
	if drag == "raw_fish":
		for lane in range(2):
			if rect_of("Shop/UpgradeStations/Fish/Boiler/Lane%d" % lane).has_point(p): return game.lanes[lane].size() < 6
	if drag == "new_skewer": return rect_of("Shop/UpgradeStations/Fish/Assembly").has_point(p) and game.skewer_count < 0
	return false

func finish_upgrade_drop(p: Vector2) -> bool:
	if drag == "new_skewer": return game.place_skewer()
	for lane in range(2):
		if rect_of("Shop/UpgradeStations/Fish/Boiler/Lane%d" % lane).has_point(p): return game.add_fish(lane)
	return false

func purchase_egg_fast() -> void:
	purchase_upgrade("egg_fast")

func purchase_auto_tea() -> void:
	purchase_upgrade("auto_tea")

func purchase_jelly() -> void:
	purchase_upgrade("jelly")

func purchase_siumai() -> void:
	purchase_upgrade("siumai")

func purchase_fish() -> void:
	purchase_upgrade("fish")

func purchase_fish_fast() -> void:
	purchase_upgrade("fish_fast")

func test_base() -> void:
	start_upgrade_test([])

func test_egg_fast() -> void:
	start_upgrade_test(["egg_fast"])

func test_auto_tea() -> void:
	start_upgrade_test(["auto_tea"])

func test_jelly() -> void:
	start_upgrade_test(["jelly"])

func test_siumai() -> void:
	start_upgrade_test(["siumai"])

func test_fish() -> void:
	start_upgrade_test(["fish"])

func test_fish_fast() -> void:
	start_upgrade_test(["fish", "fish_fast"])

func test_all() -> void:
	start_upgrade_test(["egg_fast", "auto_tea", "jelly", "siumai", "fish", "fish_fast"])

func texture_point_global(visual: TextureRect, uv: Vector2) -> Vector2:
	var rendered_size := visual.size
	var padding := Vector2.ZERO
	if visual.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		var texture_size := visual.texture.get_size()
		rendered_size = texture_size * minf(visual.size.x / texture_size.x, visual.size.y / texture_size.y)
		padding = (visual.size - rendered_size) * 0.5
	return visual.get_global_transform() * (padding + rendered_size * uv)

func item_in_transit(item: String) -> bool:
	return drag == item or (return_time > 0.0 and return_item == item)
