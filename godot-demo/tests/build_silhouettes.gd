extends SceneTree
func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://ui/customer_occluders")
	for portrait in ["granny","student","office","worker"]:
		var img := Image.load_from_file("res://assets/customers/"+portrait+".png")
		var bitmap := BitMap.new();bitmap.create_from_image_alpha(img,.35)
		var shapes := bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,img.get_size()),4.0)
		var largest := PackedVector2Array()
		var area := 0.0
		for shape in shapes:
			var bounds := Rect2(shape[0],Vector2.ZERO)
			for point in shape: bounds=bounds.expand(point)
			if bounds.get_area()>area:largest=shape;area=bounds.get_area()
		for i in range(largest.size()):largest[i]/=Vector2(img.get_size())
		var polygon := OccluderPolygon2D.new();polygon.polygon=largest;polygon.cull_mode=OccluderPolygon2D.CULL_DISABLED
		assert(ResourceSaver.save(polygon,"res://ui/customer_occluders/"+portrait+".tres")==OK)
		print(portrait,": ",largest.size()," silhouette vertices")
	quit()
