extends SceneTree
var game: Node3D
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	while not game.building.navigation_ready: await physics_frame
	game.start_match(0,1)
	Engine.time_scale = 6.0
	var started := Time.get_ticks_msec()
	var seen_round := 1
	var bot_kills := 0
	var saw_plant := false
	while game.round_number < 3 and Time.get_ticks_msec()-started<65000:
		await physics_frame
		saw_plant = saw_plant or game.bomb_planted
		if game.round_number != seen_round:
			seen_round = game.round_number
			print("SIM ROUND ",seen_round," SCORE ",game.score)
		bot_kills = 0
		for bot in game.bots: bot_kills += bot.kills
	Engine.time_scale = 1.0
	print("BOT SIM: rounds=",game.round_number," scores=",game.score," bot_kills=",bot_kills," planted=",saw_plant)
	for bot in game.bots: print(bot.actor_name," health=",bot.health," position=",bot.position)
	var ready: bool = game.round_number>=3 and bot_kills>0
	if not ready: push_error("Bot match did not complete two combat rounds")
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if ready else 1)
