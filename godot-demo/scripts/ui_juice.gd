extends Node
## Add as a child of any existing Control. Authored layout and texture stay untouched.
@export_enum("Button", "Entrance", "Value") var mode := 0
@export_range(0.0, 0.5, 0.01) var delay := 0.0
@export_range(0.1, 1.0, 0.01) var duration := 0.32
@export_range(1.0, 1.15, 0.005) var hover_scale := 1.045
@export_range(0.0, 4.0, 0.1) var tilt_degrees := 1.8
@export_range(1.0, 1.3, 0.01) var value_scale := 1.12
var target: Control
var base_scale: Vector2
var base_pivot: Vector2
var base_rotation: float
var base_modulate: Color
var motion: Tween
var hovered := false
var held := false
var last_text := ""
var initialized := false

func _ready() -> void:
	initialize.call_deferred()

func initialize() -> void:
	target = get_parent() as Control
	if target == null: return
	base_scale = target.scale
	base_pivot = target.pivot_offset
	base_rotation = target.rotation
	base_modulate = target.modulate
	initialized = true
	target.visibility_changed.connect(visibility_updated)
	if mode == 0 and target is BaseButton:
		target.mouse_entered.connect(func(): hovered = true; update_button())
		target.mouse_exited.connect(func(): hovered = false; update_button())
		target.focus_entered.connect(update_button)
		target.focus_exited.connect(update_button)
		target.button_down.connect(func(): held = true; update_button())
		target.button_up.connect(func(): held = false; update_button())
	if target is Label: last_text = target.text
	visibility_updated()
	set_process(mode == 2 or mode == 0)

func stop_motion() -> void:
	if motion and motion.is_valid(): motion.kill()
	motion = null

func restore() -> void:
	stop_motion()
	target.scale = base_scale
	target.pivot_offset = base_pivot
	target.rotation = base_rotation
	target.modulate = base_modulate

func visibility_updated() -> void:
	if not initialized: return
	held = false
	hovered = false
	restore()
	if target is Label: last_text = target.text
	if mode == 1 and target.is_visible_in_tree():
		target.pivot_offset = target.size * 0.5
		target.scale = base_scale * 0.92
		target.modulate.a = 0.0
		motion = create_tween()
		if delay > 0: motion.tween_interval(delay)
		motion.tween_property(target, "scale", base_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		motion.parallel().tween_property(target, "modulate", base_modulate, duration * 0.7)
		motion.tween_callback(restore)

func update_button() -> void:
	if not initialized or not target.is_visible_in_tree(): return
	stop_motion()
	var active: bool = not target.disabled and (hovered or target.has_focus())
	var amount := 0.94 if held and not target.disabled else hover_scale if active else 1.0
	# Limit edge travel on wide buttons rather than giving every button the same angle.
	var angle := deg_to_rad(tilt_degrees) * minf(1.0, 110.0 / maxf(1.0, target.size.x)) if active and not held else 0.0
	target.pivot_offset = target.size * 0.5
	motion = create_tween().set_parallel(true)
	motion.tween_property(target, "scale", base_scale * amount, 0.10 if held else duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	motion.tween_property(target, "rotation", base_rotation + angle, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not active and not held: motion.chain().tween_callback(restore)

func _process(_delta: float) -> void:
	if not initialized or not target.is_visible_in_tree(): return
	if mode == 0:
		if target.disabled and (held or hovered):
			held = false
			hovered = false
			update_button()
	elif mode == 2 and target is Label and target.text != last_text:
		last_text = target.text
		stop_motion()
		target.pivot_offset = target.size * 0.5
		motion = create_tween()
		motion.tween_property(target, "scale", base_scale * value_scale, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		motion.tween_property(target, "scale", base_scale, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		motion.tween_callback(restore)
