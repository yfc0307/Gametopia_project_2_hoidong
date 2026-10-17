extends Control
@export_range(0.0, 6.0, 0.1) var wave_height := 2.4
@export_range(0.0, 20.0, 0.1) var wave_speed := 9.0
@export_range(0.1, 2.0, 0.05) var letter_phase := 0.75
@export var money_wave: RichTextEffect
@export var timer_wave: RichTextEffect
@export var orders_wave: RichTextEffect
var frozen := false
func set_frozen(value: bool) -> void:
	frozen = value
func _process(delta: float) -> void:
	if frozen or not is_visible_in_tree(): return
	for effect in [money_wave, timer_wave, orders_wave]:
		effect.amplitude = wave_height
		effect.letter_phase = letter_phase
		# Hold the whole revenue group at its current wave phase during the income pop/count.
		if effect == money_wave and $Money/Amount.is_animating(): continue
		effect.phase += delta * wave_speed
