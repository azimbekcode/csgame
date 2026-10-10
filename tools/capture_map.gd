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
		"front": [Vector3(0,19,-47),Vector3(0,8,-4)],
		"front_ground": [Vector3(0,0.75,-46),Vector3(0,16,0)],
		"rear": [Vector3(23,7,39),Vector3(2,4,20)],
		"rear_stairs": [Vector3(16,2.3,34),Vector3(6,3,21.6)],
		"atrium": [Vector3(3,1.9,5.2),Vector3(-2,4.8,-4)],
		"gallery": [Vector3(8.2,13.7,0),Vector3(-3,10,0)],
		"lift": [Vector3(0.4,1.65,18.6),Vector3(-4.4,1.5,16.2)],
		"lift_closed": [Vector3(0.4,1.65,18.6),Vector3(-4.4,1.5,16.2)],
		"room_doors": [Vector3(-7.5,5.65,0),Vector3(-11,5.4,0)],
		"classroom": [Vector3(-12.6,13.7,0),Vector3(-18.4,13.3,0)],
		"garden": [Vector3(23,1.6,-23),Vector3(33,4,-15)]}
	var selected := OS.get_cmdline_user_args()
	for name in shots:
		if not selected.is_empty() and not name in selected: continue
		if name=="lift":
			game.player.global_position = game.building.lift.to_global(Vector3(-2.4,0.05,0))
			for frame in range(50): await physics_frame
		else:
			game.player.global_position = Vector3(0,0.05,5)
			if name=="lift_closed":
				for frame in range(230): await physics_frame
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
