@tool
extends LightOccluder2D
const SHAPES = {
	"hong-kong-tram-watercolor": preload("res://ui/customer_occluders/tram.tres"),
	"granny": preload("res://ui/customer_occluders/granny.tres"),
	"student": preload("res://ui/customer_occluders/student.tres"),
	"office": preload("res://ui/customer_occluders/office.tres"),
	"worker": preload("res://ui/customer_occluders/worker.tres")
}
var previous_state: Array = []
@export var window_clip: NodePath = NodePath("../../../..")
func _ready() -> void:
	occluder = OccluderPolygon2D.new()
	occluder.cull_mode = OccluderPolygon2D.CULL_DISABLED
	get_parent().visibility_changed.connect(hide_with_portrait)
func _process(_delta: float) -> void:
	var portrait := get_parent() as TextureRect
	var window := get_node_or_null(window_clip) as Control
	if portrait == null or portrait.texture == null or window == null or not portrait.is_visible_in_tree():
		visible = false
		previous_state.clear()
		return
	var state: Array = [portrait.texture, portrait.size, portrait.get_global_transform(), window.size, window.get_global_transform()]
	if state == previous_state: return
	previous_state = state
	var key := portrait.texture.resource_path.get_file().get_basename()
	if not SHAPES.has(key): visible = false; return
	var image_size := portrait.texture.get_size()
	var draw_size := image_size * minf(portrait.size.x / image_size.x, portrait.size.y / image_size.y)
	var padding := (portrait.size - draw_size) * 0.5
	var shape := PackedVector2Array()
	for point in SHAPES[key].polygon: shape.append(padding + point * draw_size)
	var clip := PackedVector2Array()
	var relative := portrait.get_global_transform().affine_inverse() * window.get_global_transform()
	for point in [Vector2.ZERO, Vector2(window.size.x,0), window.size, Vector2(0,window.size.y)]: clip.append(relative * point)
	var intersections := Geometry2D.intersect_polygons(shape,clip)
	visible = not intersections.is_empty()
	if visible: occluder.polygon = intersections[0]

func hide_with_portrait() -> void:
	if not get_parent().is_visible_in_tree():
		visible = false
		previous_state.clear()
