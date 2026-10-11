extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	while not game.building.navigation_ready: await process_frame
	game.explore_map()
	game.set_process(false)
	var player = game.player
	player.reset_to(Vector3(21,-0.85,0),PI/2)
	Input.action_press("forward")
	var reached_roof := false
	for frame in range(340):
		await physics_frame
		if player.position.y>=16 and not player.ladder_climbing:
			reached_roof = true
			break
	Input.action_release("forward")
	if not reached_roof:
		push_error("Roof ladder must carry the player from courtyard to roof")
		quit(1)
		return
	for frame in range(15): await physics_frame
	if not player.is_on_floor() or absf(player.position.y-16.05)>0.2:
		push_error("Roof ladder exit must leave the player on a solid roof landing")
		quit(1)
		return
	# Walk past the small ladder platform: the entire roof must support us.
	Input.action_press("forward")
	for frame in range(50): await physics_frame
	Input.action_release("forward")
	for frame in range(10): await physics_frame
	if player.position.y<15.9 or not player.is_on_floor() or player.position.x>17:
		push_error("Player must remain on the roof after walking away from the ladder")
		quit(1)
		return
	player.rotation.y = -PI/2
	Input.action_press("forward")
	for frame in range(100):
		await physics_frame
		if player.position.x>=18.9: break
	Input.action_release("forward")
	for frame in range(8): await physics_frame
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	player._unhandled_input(event)
	Input.action_press("back")
	var returned := false
	for frame in range(340):
		await physics_frame
		if not player.ladder_climbing and player.position.y<0:
			returned = true
			break
	Input.action_release("back")
	if not returned or absf(player.position.y+0.9)>0.2:
		push_error("Roof ladder must let the player descend to the courtyard")
		quit(1)
		return
	print("LADDER PASS: courtyard ascent, left facade, walkable roof beyond ladder platform and full descent")
	game.queue_free()
	await process_frame
	await process_frame
	quit()
