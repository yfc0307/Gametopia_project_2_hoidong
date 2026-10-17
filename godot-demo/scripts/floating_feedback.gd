extends Node2D
@export_range(0.5,4.0,0.1) var duration := 2.2
var motion: Tween
var rating := 0
func play(message: String, tint: Color, drift: Vector2, result: int) -> void:
	rating = result
	$Text.text = message
	$Text.add_theme_color_override("font_color",tint)
	modulate.a = 0.0
	scale = Vector2(0.88,0.88)
	var destination := position+drift
	destination.y = maxf(100.0,destination.y)
	motion = create_tween().set_parallel(true)
	motion.finished.connect(func(): motion = null)
	motion.tween_property(self,"position",destination,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion.tween_property(self,"scale",Vector2.ONE,.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	motion.tween_property(self,"modulate:a",1.0,.12)
	motion.tween_property(self,"modulate:a",0.0,duration-.4).set_delay(.4)
	motion.chain().tween_callback(queue_free)
func set_frozen(value: bool) -> void:
	if motion and motion.is_valid():
		if value:motion.pause()
		else:motion.play()
