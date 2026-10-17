extends Control
const POPUP = preload("res://scenes/components/floating_feedback.tscn")
@export var correct_text := "唔該~"
@export var imperfect_text := "唔係好口岩wo"
@export var rejected_text := "都無話要呢樣"
@export var correct_color := Color(0.36,0.94,0.49)
@export var imperfect_color := Color(1.0,0.80,0.25)
@export var rejected_color := Color(1.0,0.35,0.38)
@export_range(0.5,4.0,0.1) var duration := 2.2
var rng := RandomNumberGenerator.new()
var frozen := false
func _ready() -> void:
	rng.randomize()
func show_result(world_position: Vector2, rating: int) -> Node2D:
	var popup = POPUP.instantiate()
	add_child(popup)
	popup.position = get_global_transform().affine_inverse()*world_position+Vector2(rng.randf_range(-14,14),rng.randf_range(-4,4))
	popup.position.y = maxf(135,popup.position.y)
	popup.duration = duration
	popup.play([correct_text,imperfect_text,rejected_text][rating],[correct_color,imperfect_color,rejected_color][rating],Vector2(rng.randf_range(-45,45),-rng.randf_range(55,80)),rating)
	popup.set_frozen(frozen)
	return popup
func set_frozen(value: bool) -> void:
	frozen = value
	for popup in get_children():popup.set_frozen(value)
func clear() -> void:
	for popup in get_children():
		remove_child(popup)
		popup.queue_free()
