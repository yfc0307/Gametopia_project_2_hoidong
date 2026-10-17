extends Control
@export var sunlight_path: NodePath = NodePath("../../WindowSunlight")
@export_range(0.0,30.0,0.5) var first_delay_min := 4.0
@export_range(0.0,30.0,0.5) var first_delay_max := 8.0
@export_range(1.0,90.0,1.0) var interval_min := 12.0
@export_range(1.0,90.0,1.0) var interval_max := 24.0
@export_range(30.0,2000.0,10.0,"or_greater") var travel_speed := 125.0
@export_range(0.0,0.2,0.01) var speed_variation := 0.08
@export_range(0.0,1.0,0.01) var tram_shadow_darkness := 0.90
@export_range(-1.0,1.0,0.01) var shadow_slant := 0.28
var projection: ColorRect
var rng := RandomNumberGenerator.new()
var wait_left := 0.0
var moving := false
var speed := 125.0
func _ready() -> void:
	projection = get_node_or_null("../../TramShadowProjection") as ColorRect
	if projection: projection.material = projection.material.duplicate()
	rng.randomize()
	reset_traffic()
func reset_traffic() -> void:
	moving = false
	$Tram.visible = false
	if is_instance_valid(projection): projection.visible = false
	wait_left = rng.randf_range(minf(first_delay_min,first_delay_max),maxf(first_delay_min,first_delay_max))
func start_pass() -> void:
	moving = true
	speed = travel_speed*rng.randf_range(1.0-speed_variation,1.0+speed_variation)
	$Tram.position.x = -$Tram.size.x*$Tram.scale.x-10.0
	$Tram.visible = true
func _process(delta: float) -> void:
	var sunlight=get_node_or_null(sunlight_path)
	if not is_visible_in_tree() or sunlight == null or sunlight.frozen: return
	if moving:
		$Tram.position.x += speed*delta
		if $Tram.position.x > get_parent().size.x+10.0:
			moving = false
			$Tram.visible = false
			wait_left = rng.randf_range(minf(interval_min,interval_max),maxf(interval_min,interval_max))
	else:
		wait_left -= delta
		if wait_left<=0.0:start_pass()

	update_projection(sunlight)

func update_projection(sunlight: Node) -> void:
	if not is_instance_valid(projection):
		projection = get_node_or_null("../../TramShadowProjection") as ColorRect
	if projection == null: return
	projection.visible = moving and $Tram.visible and sunlight.enabled and sunlight.sunlight_energy > 0.0
	if not projection.visible: return
	var art: TextureRect = $Tram/Art
	var texture_size := art.texture.get_size()
	var draw_size := texture_size*minf(art.size.x/texture_size.x,art.size.y/texture_size.y)
	var padding := (art.size-draw_size)*0.5
	var window: Rect2 = get_parent().get_global_rect()
	projection.material.set_shader_parameter("tram_texture",art.texture)
	var drawn: Rect2 = art.get_global_transform()*Rect2(padding,draw_size)
	projection.material.set_shader_parameter("tram_rect",Vector4(drawn.position.x,drawn.position.y,drawn.size.x,drawn.size.y))
	projection.material.set_shader_parameter("image_rect",Vector4(padding.x,padding.y,draw_size.x,draw_size.y))
	projection.material.set_shader_parameter("window_rect",Vector4(window.position.x,window.position.y,window.size.x,window.size.y))
	projection.material.set_shader_parameter("shadow_slant",shadow_slant)
	projection.material.set_shader_parameter("darkness",tram_shadow_darkness)
