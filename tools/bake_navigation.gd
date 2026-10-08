extends SceneTree
## Regenerate navigation after editing the map's collision geometry.
func _initialize() -> void:
	call_deferred("bake")
func bake() -> void:
	var building := Node3D.new()
	building.set_script(load("res://scripts/building_map.gd"))
	building.force_bake = true
	root.add_child(building)
	var deadline := Time.get_ticks_msec()+120000
	while not building.navigation_ready:
		await process_frame
		if Time.get_ticks_msec()>deadline:
			push_error("Navigation bake timed out")
			quit(1)
			return
	DirAccess.make_dir_recursive_absolute("res://maps")
	var nav: NavigationMesh = building.navigation_region.navigation_mesh
	if nav.get_polygon_count()==0:
		push_error("Empty navigation mesh; keeping the existing resource")
		quit(1)
		return
	var result := ResourceSaver.save(nav,"res://maps/campus_navigation.tres")
	print("NAVIGATION: ",nav.get_polygon_count()," polygons, save status=",result)
	building.queue_free()
	await process_frame
	quit(0 if result==OK else 1)
