extends "res://scripts/wave_label.gd"
## Only this numeral animates; its parent caption and the HUD panels stay still.
@export_range(0.1, 1.0, 0.01) var count_duration := 0.36
@export_range(1.0, 1.6, 0.01) var pop_scale := 1.25
@export_range(-20.0, 20.0, 0.5) var pop_angle := -8.0
@export_range(0.1, 1.0, 0.01) var settle_duration := 0.4
var target_amount := 0
var displayed_amount := 0.0
var base_scale := Vector2.ONE
var base_rotation := 0.0
var counter: Tween
var bounce: Tween
var frozen := false

func _ready() -> void:
	base_scale = scale
	base_rotation = rotation
	pivot_offset = Vector2(0.0, size.y * 0.5)

func stop_animation() -> void:
	if counter and counter.is_valid(): counter.kill()
	if bounce and bounce.is_valid(): bounce.kill()
	counter = null
	bounce = null

func draw_amount(value: float) -> void:
	displayed_amount = value
	set_wave_text(str(roundi(value)))

func set_amount(value: int, instant := false) -> void:
	if not instant and value == target_amount: return
	var rising := value > target_amount
	target_amount = value
	stop_animation()
	if instant or not rising or not is_visible_in_tree():
		draw_amount(float(value))
		scale = base_scale
		rotation = base_rotation
		return
	counter = create_tween()
	counter.tween_method(draw_amount, displayed_amount, float(value), count_duration)
	counter.tween_callback(func(): counter = null)
	bounce = create_tween().set_parallel(true)
	bounce.tween_property(self, "scale", base_scale * pop_scale, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce.tween_property(self, "rotation", base_rotation + deg_to_rad(pop_angle), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bounce.chain().tween_property(self, "scale", base_scale, settle_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce.parallel().tween_property(self, "rotation", base_rotation, settle_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bounce.chain().tween_callback(func(): bounce = null)
	set_frozen(frozen)

func set_frozen(value: bool) -> void:
	frozen = value
	for tween in [counter, bounce]:
		if tween and tween.is_valid():
			if frozen: tween.pause()
			else: tween.play()

func is_animating() -> bool:
	return (counter != null and counter.is_valid()) or (bounce != null and bounce.is_valid())
