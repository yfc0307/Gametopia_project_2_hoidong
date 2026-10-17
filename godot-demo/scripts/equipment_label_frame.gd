@tool
extends NinePatchRect
## Only this decorative frame follows its label; equipment and label placement remain authored.
var pending := false
func _ready() -> void:
	var label := get_parent() as Control
	if label and not label.resized.is_connected(queue_fit): label.resized.connect(queue_fit)
	if not resized.is_connected(queue_fit): resized.connect(queue_fit)
	queue_fit()
func queue_fit() -> void:
	if pending: return
	pending = true
	fit_label.call_deferred()
func fit_label() -> void:
	pending = false
	if not is_inside_tree() or not get_parent() is Control: return
	if anchor_left == 0.0 and anchor_top == 0.0 and anchor_right == 1.0 and anchor_bottom == 1.0 and offset_left == -9.0 and offset_top == -4.0 and offset_right == 9.0 and offset_bottom == 4.0 and scale == Vector2.ONE and rotation == 0.0: return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = -9.0
	offset_top = -4.0
	offset_right = 9.0
	offset_bottom = 4.0
	scale = Vector2.ONE
	rotation = 0.0
