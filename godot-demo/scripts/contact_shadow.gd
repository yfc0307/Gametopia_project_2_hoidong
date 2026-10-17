@tool
extends ColorRect
## Instance beside a texture and assign Target Visual. Only this effect follows its geometry.
@export var target_visual: NodePath = NodePath("../Art"):
	set(value):
		target_visual = value
		if is_inside_tree(): bind_target.call_deferred()
@export var shadow_color := Color(0.25, 0.13, 0.065, 0.32):
	set(value):
		shadow_color = value
		update_material()
@export var contact_center := Vector2(0.5, 0.93):
	set(value):
		contact_center = value
		update_material()
@export var contact_radius := Vector2(0.43, 0.065):
	set(value):
		contact_radius = value
		update_material()
@export var always_lifted := false
var target: Control
var lift_amount := 0.0
var lift_goal := 0.0
func _ready() -> void:
	material = material.duplicate()
	update_material()
	bind_target()
func get_target() -> Control:
	return target
func bind_target() -> void:
	if is_instance_valid(target) and target.item_rect_changed.is_connected(follow_target):
		target.item_rect_changed.disconnect(follow_target)
	if is_instance_valid(target) and target.visibility_changed.is_connected(sync_visibility):
		target.visibility_changed.disconnect(sync_visibility)
	target = get_node_or_null(target_visual) as Control
	if target == self: target = null
	if target:
		target.item_rect_changed.connect(follow_target)
		target.visibility_changed.connect(sync_visibility)
		follow_target()
	sync_visibility()
func follow_target() -> void:
	if not is_instance_valid(target): return
	var relative: Transform2D = get_parent().get_global_transform().affine_inverse() * target.get_global_transform()
	position = relative.origin
	scale = relative.get_scale()
	rotation = relative.get_rotation()
	size = target.size + Vector2(0, 12)
func set_lifted(value: bool) -> void:
	lift_goal = 1.0 if value or always_lifted else 0.0
func _process(delta: float) -> void:
	var goal := 1.0 if always_lifted else lift_goal
	lift_amount = lerpf(lift_amount, goal, 1.0 - exp(-18.0 * delta))
	if material: material.set_shader_parameter("lift", lift_amount)
func update_material() -> void:
	if not material: return
	material.set_shader_parameter("shadow_color", shadow_color)
	material.set_shader_parameter("contact_center", contact_center)
	material.set_shader_parameter("contact_radius", contact_radius)

func sync_visibility() -> void:
	# Sibling shadows must disappear with their source, just like shadows nested under it.
	visible = is_instance_valid(target) and target.is_visible_in_tree()
