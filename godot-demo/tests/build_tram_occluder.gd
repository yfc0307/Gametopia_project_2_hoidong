extends SceneTree
func _init() -> void:
	var img=Image.load_from_file("res://assets/hong-kong-tram-watercolor.png")
	var bits=BitMap.new();bits.create_from_image_alpha(img,.35)
	var shapes=bits.opaque_to_polygons(Rect2i(Vector2i.ZERO,img.get_size()),8)
	var best=PackedVector2Array();var area:=0.0
	for shape in shapes:
		var bounds=Rect2(shape[0],Vector2.ZERO)
		for p in shape:bounds=bounds.expand(p)
		if bounds.get_area()>area:best=shape;area=bounds.get_area()
	for i in range(best.size()):best[i]/=Vector2(img.get_size())
	var polygon=OccluderPolygon2D.new();polygon.polygon=best;polygon.cull_mode=OccluderPolygon2D.CULL_DISABLED
	assert(ResourceSaver.save(polygon,"res://ui/customer_occluders/tram.tres")==OK)
	print("TRAM silhouette: ",best.size()," vertices")
	quit()
