extends SceneTree
## Reproducible in-engine views; requires a graphical display (Xvfb works on Linux).
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1440,900)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	game.set_process(false)
	game.hud.hide()
	game.player.weapon_model.hide()
	var camera: Camera3D = game.player.view_camera
	camera.fov = 65
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	var shots := {
		"atrium_ceiling": [Vector3(0,0.5,0),Vector3(1,20,0)],
		"dome_oculus": [Vector3(5,33,-7),Vector3(0,27.5,0)],
		"front": [Vector3(0,19,-47),Vector3(0,8,-4)],
		"front_ground": [Vector3(0,0.75,-46),Vector3(0,16,0)],
		"campus_link_garden": [Vector3(-20,1.0,28),Vector3(-24,3.2,43)],
		"perimeter_front": [Vector3(0,8,-65),Vector3(0,5,-7)],
		"perimeter_overview": [Vector3(65,48,-72),Vector3(-3,2,1)],
		"left_lane": [Vector3(23.7,1.05,14.5),Vector3(25,1.1,-15)],
		"left_lane_overview": [Vector3(44,17,29),Vector3(22,2,0)],
		"stone_walkway": [Vector3(27,1.4,23),Vector3(18,-0.5,11)],
		"lift_retracted": [Vector3(-2.2,-0.15,12),Vector3(-4.4,-0.45,16.2)],
		"lift_button_right": [Vector3(-2.2,5.65,12),Vector3(-4.4,5.35,16.2)],
		"campus_link": [Vector3(-9,2,29.5),Vector3(-18,3,43)],
		"campus_link_front": [Vector3(-15.5,0.75,28),Vector3(-15.5,3,44)],
		"lift_rear_filled": [Vector3(0.5,0,19.1),Vector3(-4.4,-0.2,18.4)],
		"rear": [Vector3(23,7,39),Vector3(2,4,20)],
		"rear_stairs": [Vector3(16,2.3,34),Vector3(6,3,21.6)],
		"atrium": [Vector3(3,1.9,5.2),Vector3(-2,4.8,-4)],
		"gallery": [Vector3(8.2,13.7,0),Vector3(-3,10,0)],
		"lift": [Vector3(0.4,1.65,18.6),Vector3(-4.4,1.5,16.2)],
		"lift_closed": [Vector3(0.4,1.65,18.6),Vector3(-4.4,1.5,16.2)],
		"room_doors": [Vector3(-7.5,5.65,0),Vector3(-11,5.4,0)],
		"inner_stairs": [game.building.stair_point(-1,0,12.5,5.65),game.building.stair_point(-1,-1.05,17.7,6.2)],
		"front_reference": [Vector3(18,4,-36),Vector3(0,2.3,-25)],
		"front_left_passage": [Vector3(8.1,1.5,-33.7),Vector3(4.7,1.2,-23)],
		"front_left_passage_landing": [Vector3(8.8,2.2,-34.3),Vector3(5.5,-0.9,-29)],
		"front_lower_side_steps": [Vector3(-6,1.0,-24.1),Vector3(1.2,-0.4,-21.2)],
		"front_three_piers": [Vector3(9.4,1.6,-30.4),Vector3(3.7,0.6,-24.5)],
		"front_pier_doorway": [Vector3(5.9,-0.15,-24.1),Vector3(0,-0.1,-24.1)],
		"front_reference_other": [Vector3(-18,3.5,-36),Vector3(0,2.3,-25)],
		"lift_open_lobby": [Vector3(-1,5.65,12.8),Vector3(-4.4,5.5,16.2)],
		"roof_ladder": [Vector3(35,7,-8),Vector3(20,7,0)],
		"rear_guidance": [Vector3(0,-0.15,19.5),Vector3(0,-0.8,11)],
		"stairs_top": [game.building.stair_point(-1,1.05,13.5,13.65),game.building.stair_point(-1,0,18.2,10)],
		"lift_between": [Vector3(-4.4,7.4,16.2),Vector3(-2.8,7.4,16.2)],
		"front_entry_flat": [Vector3(0,-0.15,-21.5),Vector3(0,-0.15,-8)],
		"front_entry_zero": [Vector3(-7,1.1,-24),Vector3(0,-0.35,-20.5)],
		"front_stair_pair": [Vector3(0,5.65,4.5),Vector3(0,6,-11)],
		"window_view": [Vector3(-18.5,13.9,0),Vector3(-28,13.9,0)],
		"lift_mirror": [Vector3(-4.3,1.65,16.2),Vector3(-5.55,1.65,16.2)],
		"classroom": [Vector3(-12.6,13.7,0),Vector3(-18.4,13.3,0)],
		"classroom_front": [Vector3(-12.0,13.65,0.6),Vector3(-12.5,13.3,3.35)],
		"front_left_clear": [Vector3(35,1.6,-45),Vector3(10,5,-5)],
		"garden": [Vector3(23,1.6,-23),Vector3(33,4,-15)]}
	var selected := OS.get_cmdline_user_args()
	for name in shots:
		if not selected.is_empty() and not name in selected: continue
		if name=="lift_retracted":
			game.player.global_position = game.building.lift.to_global(Vector3(-2.4,-1.75,0))
			for frame in range(50): await physics_frame
		elif name=="lift_between":
			var lift = game.building.lift
			lift.set_physics_process(false)
			lift.cabin.position.y = 5.75
			lift.door_open.fill(0.0)
			lift._update_gates()
			game.player.reset_to(Vector3(-4.4,5.8,16.2),PI/2)
		elif name=="lift":
			game.player.global_position = game.building.lift.to_global(Vector3(-2.4,0.05,0))
			for frame in range(50): await physics_frame
		elif name=="lift_mirror":
			game.player.reset_to(game.building.lift.global_position+Vector3(0,0.05,0),PI/2)
			for frame in range(50): await physics_frame
		else:
			game.player.global_position = Vector3(0,0.05,5)
			if name=="lift_closed":
				for frame in range(230): await physics_frame
		if name in ["campus_link","campus_link_front","campus_link_garden"]:
			shots[name] = [game.building.get_node("RearCampusLink").to_global(shots[name][0]),game.building.get_node("RearCampusLink").to_global(shots[name][1])]
		camera.global_position = shots[name][0]
		camera.look_at(shots[name][1])
		for frame in range(5): await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("res://docs/screenshots/"+name+".png")
		print("CAPTURE ",name," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if not selected.is_empty():
		game.queue_free()
		await process_frame
		quit()
		return
	var soldier := Node3D.new()
	soldier.set_script(load("res://scripts/soldier_model.gd"))
	soldier.weapon = "m4"
	soldier.position = Vector3(0,4.0,-22)
	soldier.rotation.y = 0
	game.add_child(soldier)
	camera.global_position = Vector3(1.4,5.4,-25)
	camera.look_at(Vector3(0,5.0,-22))
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/soldier.png")
	print("CAPTURE soldier")
	soldier.queue_free()
	game.hud.show()
	game.return_to_menu()
	game.player.reset_to(Vector3(0,0.05,5),0)
	camera.position = Vector3(0,1.65,0)
	camera.look_at(Vector3(0,4,-4))
	await save_view("menu")
	while not game.building.navigation_ready: await physics_frame
	game.start_match(0,1)
	game.phase = "active"
	game.player.reset_to(Vector3(0,0.05,4),0)
	game.player.weapon_model.show()
	for bot in game.bots:
		bot.set_physics_process(false)
		bot.position = Vector3(-4+game.bots.find(bot)*1.2,0.05,-3)
		bot.rotation.y = PI
	await save_view("combat")
	game.player.money = 5000
	game.hud.toggle_shop()
	await save_view("shop")
	game.queue_free()
	await process_frame
	quit()

func save_view(name: String) -> void:
	for frame in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+name+".png")
	print("CAPTURE ",name)
