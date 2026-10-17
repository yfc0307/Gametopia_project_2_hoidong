@tool
extends Control
## Resize the authored inner layout as a unit. Never rewrite child positions.
@export var design_size := Vector2(130, 123):
	set(value):
		design_size = value
		apply_layout.call_deferred()

func _ready() -> void:
	resized.connect(apply_layout)
	apply_layout()

func apply_layout() -> void:
	var design := get_node_or_null("Design") as Control
	if design == null or design_size.x <= 0 or design_size.y <= 0: return
	design.size = design_size
	design.scale = size / design_size
