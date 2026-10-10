extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	while not game.building.navigation_ready: await physics_frame
	game.explore_map()
	game.set_process(false)
	var p = game.player
	var yaw: float = game.building.get_node("MarkedStairBay_-1").rotation.y
	p.reset_to(game.building.stair_point(-1,-1.05,14.0,-1.63),yaw+PI)
	for i in range(10): await physics_frame
	var start: float = p.position.y
	Input.action_press("forward")
	var maximum := 0.0
	for i in range(65):
		await physics_frame
		maximum = maxf(maximum,absf(p.stair_view_offset))
	Input.action_release("forward")
	if not (p.position.y>start+0.6 and maximum>0.07):
		push_error("Internal stair ascent must produce tread-paced movement")
		quit(1)
		return
	var top: float = p.position.y
	p.rotation.y = yaw
	Input.action_press("forward")
	var descending := 0.0
	for i in range(50):
		await physics_frame
		descending = maxf(descending,absf(p.stair_view_offset))
	Input.action_release("forward")
	if not (p.position.y<top-0.5 and descending>0.07):
		push_error("Internal stair descent must produce tread-paced movement")
		quit(1)
		return
	var noses: int = game.building.find_children("TreadNosing*","Node3D",true,false).size()
	var treads := 0
	for surface in game.building.stair_surfaces: treads += surface.get_meta("treads").steps
	if noses!=treads:
		push_error("Every stair tread needs a visible edge")
		quit(1)
		return
	print("GAIT PASS: inner stair ascent/descent, tread offset ",maximum,"/",descending,", visible tread edges=",noses)
	game.queue_free()
	await process_frame
	await process_frame
	quit()
