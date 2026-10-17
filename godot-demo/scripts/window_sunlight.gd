@tool
extends Node2D
@export var enabled := true
@export_range(0.0, 6.0, 0.01, "or_greater") var sunlight_energy := 0.8
@export_range(0.0, 2.0, 0.01) var patch_strength := 0.65
@export_range(0.0, 0.7, 0.01) var cloud_shadow_strength := 0.35
@export var sunlight_color := Color(1.0, 0.86, 0.61)
@export_range(0.0, 1.0, 0.01) var cloud_amount := 0.45
@export_range(0.0, 0.3, 0.005) var cloud_speed := 0.045
var frozen := false
var elapsed := 0.0
const CLOUD_SIZE := 96
var cloud_noise := FastNoiseLite.new()
var cloud_image: Image
var cloud_texture: ImageTexture
var previous_cloud_time := -100.0
var previous_cloud_settings := Vector2(-1,-1)
var initialized := false
var patch: ColorRect
var cloud_shade: ColorRect
var sun: PointLight2D

func _ready() -> void:
	initialize_if_ready()

func initialize_if_ready() -> bool:
	if initialized and is_instance_valid(patch) and is_instance_valid(cloud_shade) and is_instance_valid(sun): return true
	# @tool can reload before an open scene has received new saved child nodes.
	# Wait for the authored scene to reload instead of accessing missing children every frame.
	patch = get_node_or_null("WindowPatch") as ColorRect
	cloud_shade = get_node_or_null("CloudShade") as ColorRect
	sun = get_node_or_null("Sun") as PointLight2D
	if patch == null or cloud_shade == null or sun == null: return false
	if patch.material == null or cloud_shade.material == null: return false
	patch.material = patch.material.duplicate()
	cloud_shade.material = cloud_shade.material.duplicate()
	cloud_noise.seed = 317
	cloud_noise.frequency = 1.0
	cloud_image = Image.create(CLOUD_SIZE,CLOUD_SIZE,false,Image.FORMAT_RGBA8)
	initialized = true
	update_cloud_texture()
	sun.texture_scale = 1500.0 / CLOUD_SIZE
	return true

func set_frozen(value: bool) -> void:
	frozen = value
func _process(delta: float) -> void:
	if not initialize_if_ready(): return
	if not frozen: elapsed += delta
	patch.material.set_shader_parameter("patch_strength", patch_strength)
	cloud_shade.visible = enabled and sunlight_energy > 0.0
	cloud_shade.material.set_shader_parameter("strength",cloud_shadow_strength)
	cloud_shade.material.set_shader_parameter("light_origin",sun.global_position)
	cloud_shade.material.set_shader_parameter("light_extent",Vector2(1500,1500)*sun.get_global_transform().get_scale())
	sun.enabled = enabled
	sun.color = sunlight_color
	sun.energy = sunlight_energy
	if absf(elapsed-previous_cloud_time) >= 0.12 or previous_cloud_settings != Vector2(cloud_amount,cloud_speed):
		update_cloud_texture()

func update_cloud_texture() -> void:
	# PointLight2D cannot use ViewportTexture. Update a small reusable image at about 8 Hz.
	if cloud_image == null or not is_instance_valid(sun) or not is_instance_valid(cloud_shade): return
	var wind := Vector2(elapsed*cloud_speed*2.0,elapsed*cloud_speed*0.23)
	for y in range(CLOUD_SIZE):
		for x in range(CLOUD_SIZE):
			var uv := (Vector2(x,y)+Vector2(0.5,0.5))/CLOUD_SIZE
			var point := uv*4.0+wind+Vector2(7.5,3.1)
			var noise_value := cloud_noise.get_noise_2d(point.x,point.y)*0.5+0.5
			var cloud := smoothstep(0.30,0.70,noise_value)
			var transmission := 1.0-clampf(cloud_amount*1.8,0.0,0.97)*cloud
			var radial := 1.0-smoothstep(0.6,1.0,(uv-Vector2(0.5,0.5)).length()*2.0)
			var value := radial*transmission
			cloud_image.set_pixel(x,y,Color(value,value,value,1))
	# Rebind the small texture so Compatibility's light atlas refreshes its contents.
	var old_texture: Texture2D = sun.texture
	if old_texture: old_texture.get_rid()
	cloud_texture = ImageTexture.create_from_image(cloud_image)
	sun.texture = cloud_texture
	cloud_shade.material.set_shader_parameter("cloud_map",cloud_texture)
	# Keep the previous texture alive until the light has removed it from its atlas.
	if old_texture: old_texture.get_rid()
	previous_cloud_time = elapsed
	previous_cloud_settings = Vector2(cloud_amount,cloud_speed)

