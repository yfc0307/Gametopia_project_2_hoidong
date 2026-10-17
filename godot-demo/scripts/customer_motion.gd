extends Control
@export_range(40.0, 240.0, 5.0) var walk_speed := 140.0
@export_range(0.0, 4.0, 0.25) var walk_bob := 1.5
@export_range(0.0,4.0,0.1) var breath_amplitude := 1.2
@export_range(1.0,8.0,0.1) var breath_period := 3.2
@export_range(0.75,1.0,0.01) var receive_scale := 0.88
@export_range(0.1,0.8,0.01) var receive_duration := 0.48
var home_scale := Vector2.ONE
var home_pivot := Vector2.ZERO
var breath_phase := 0.0
var animation_frozen := false
var receive_factor := 1.0
var receive_stretch := Vector2.ONE
var receive_lift := 0.0
@export_range(0.0,0.12,0.005) var receive_overshoot := 0.055
var receive_tween: Tween
var home_avatar: Vector2
var home_order: Vector2
var initialized := false
var was_present := false
var motion: Tween
var speed_factor := 1.0
var entering := false
var departing := false
func _ready() -> void:
	home_scale = $Avatar.scale
	home_pivot = $Avatar.pivot_offset
	breath_phase = randf()*TAU
	home_avatar = $Avatar.position
	home_order = $OrderCard.position
	$OrderCard.minimum_size_changed.connect(func(): fit_order.call_deferred())
	fit_order.call_deferred()
func reset_motion() -> void:
	if receive_tween and receive_tween.is_valid(): receive_tween.kill()
	receive_tween = null
	receive_factor = 1.0
	receive_stretch = Vector2.ONE
	receive_lift = 0.0
	$Avatar.scale = home_scale
	$Avatar.pivot_offset = home_pivot
	if motion and motion.is_valid(): motion.kill()
	initialized = false
	entering = false
	departing = false
	$Avatar.position = home_avatar
	$OrderCard.position = home_order
	$Avatar.self_modulate.a = 1.0
	$OrderCard.self_modulate.a = 1.0
func sync_presence(present: bool, frozen: bool, factor: float = 1.0) -> void:
	animation_frozen = frozen
	if receive_tween and receive_tween.is_valid():
		if frozen: receive_tween.pause()
		else: receive_tween.play()
	if not initialized and not present:
		initialized = true
		was_present = false
		$Avatar.visible = false
		$OrderCard.visible = false
		$Waiting.visible = false
		return
	if not initialized or present != was_present:
		initialized = true
		was_present = present
		if present:
			speed_factor = factor
			walk_in()
		else: walk_out()
	if motion and motion.is_valid():
		if frozen: motion.pause()
		else: motion.play()
func side_offset(right_side: bool) -> float:
	var window: Control = get_parent().get_parent()
	var edge: float = window.size.x + 20.0 if right_side else -$Avatar.size.x - 20.0
	var local_edge: Vector2 = get_global_transform().affine_inverse() * window.get_global_transform() * Vector2(edge, 0)
	return local_edge.x - home_avatar.x
func walk_in() -> void:
	if motion and motion.is_valid(): motion.kill()
	entering = true
	departing = false
	$Avatar.visible = true
	$Avatar.self_modulate.a = 1.0
	$OrderCard.visible = false
	$OrderCard.position = home_order
	$Waiting.visible = false
	var distance := side_offset(false)
	var duration := maxf(1.4, absf(distance) / (walk_speed * speed_factor))
	$Avatar.position = home_avatar + Vector2(distance, 0)
	motion = create_tween()
	motion.finished.connect(func(): motion = null)
	motion.tween_method(func(t: float):
		$Avatar.position = home_avatar + Vector2(distance * (1.0 - t), -sin(t * duration * TAU * 1.6) * walk_bob * sin(t * PI))
	, 0.0, 1.0, duration)
	motion.tween_callback(func():
		entering = false
		$Avatar.position = home_avatar
		$OrderCard.visible = true
		$OrderCard.self_modulate.a = 0.0
	)
	motion.tween_property($OrderCard, "self_modulate:a", 1.0, 0.2)
func walk_out() -> void:
	if motion and motion.is_valid(): motion.kill()
	entering = false
	departing = true
	$Avatar.visible = true
	$Avatar.self_modulate.a = 1.0
	$OrderCard.visible = false
	$Waiting.visible = false
	var start: Vector2 = $Avatar.position
	var finish := home_avatar + Vector2(side_offset(true), 0)
	var duration := maxf(1.4, absf(finish.x - start.x) / (walk_speed * speed_factor))
	motion = create_tween()
	motion.finished.connect(func(): motion = null)
	motion.tween_method(func(t: float):
		$Avatar.position = start.lerp(finish, t) + Vector2(0, -sin(t * duration * TAU * 1.6) * walk_bob * sin(t * PI))
	, 0.0, 1.0, duration)
	motion.tween_callback(func():
		departing = false
		$Avatar.visible = false
		$Waiting.visible = true
	)

func set_order_content(has_tea: bool, has_eggs: bool) -> void:
	var tea_row = $OrderCard/Bubble/Items/TeaRow
	var egg_row = $OrderCard/Bubble/Items/EggRow
	if tea_row.visible != has_tea or egg_row.visible != has_eggs:
		tea_row.visible = has_tea
		egg_row.visible = has_eggs
		fit_order.call_deferred()

func fit_order() -> void:
	$OrderCard.reset_size()
	$OrderCard/Bubble/Items.reset_size()
	$OrderCard/Bubble.reset_size()
	$OrderCard.reset_size()
	$OrderCard/Bubble/Tail.position.y = minf(60.0, $OrderCard/Bubble.size.y * 0.5)

func set_extra_order_content(jelly: bool, siumai: bool, fish: bool) -> void:
	var rows = $OrderCard/Bubble/Items
	if rows.get_node("JellyRow").visible != jelly or rows.get_node("SiumaiRow").visible != siumai or rows.get_node("FishRow").visible != fish:
		rows.get_node("JellyRow").visible = jelly
		rows.get_node("SiumaiRow").visible = siumai
		rows.get_node("FishRow").visible = fish
		fit_order.call_deferred()

func _process(delta: float) -> void:
	if animation_frozen: return
	$Avatar.scale = home_scale*receive_factor*receive_stretch
	$Avatar.pivot_offset = $Avatar.size*Vector2(.5,.7) if not is_equal_approx(receive_factor,1.0) or not receive_stretch.is_equal_approx(Vector2.ONE) else home_pivot
	if was_present and not entering and not departing and $Avatar.visible:
		breath_phase += delta*TAU/breath_period
		$Avatar.position = home_avatar+Vector2(0,sin(breath_phase)*breath_amplitude+$Avatar.size.y*receive_lift)

func play_receive_feedback() -> void:
	if receive_tween and receive_tween.is_valid(): receive_tween.kill()
	# Keep current deformation on rapid deliveries, then spring back to the authored pose.
	receive_tween = create_tween()
	receive_tween.finished.connect(func(): receive_tween = null)
	receive_tween.tween_property(self,"receive_factor",receive_scale,receive_duration*.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	receive_tween.parallel().tween_property(self,"receive_stretch",Vector2(1.045,.955),receive_duration*.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	receive_tween.parallel().tween_property(self,"receive_lift",.008,receive_duration*.18)
	receive_tween.tween_property(self,"receive_factor",1.0+receive_overshoot,receive_duration*.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	receive_tween.parallel().tween_property(self,"receive_stretch",Vector2(.975,1.025),receive_duration*.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	receive_tween.parallel().tween_property(self,"receive_lift",-.015,receive_duration*.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	receive_tween.tween_property(self,"receive_factor",.985,receive_duration*.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	receive_tween.parallel().tween_property(self,"receive_stretch",Vector2(1.01,.99),receive_duration*.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	receive_tween.parallel().tween_property(self,"receive_lift",.003,receive_duration*.24)
	receive_tween.tween_property(self,"receive_factor",1.0,receive_duration*.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	receive_tween.parallel().tween_property(self,"receive_stretch",Vector2.ONE,receive_duration*.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	receive_tween.parallel().tween_property(self,"receive_lift",0.0,receive_duration*.20)
