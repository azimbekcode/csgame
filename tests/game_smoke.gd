extends SceneTree

var passed := 0
var failed := 0
var game: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: ",label)
	else:
		failed += 1
		push_error("FAIL: "+label)

func frames(count: int) -> void:
	for index in range(count): await physics_frame

func settle(player: CharacterBody3D, count: int = 20) -> void:
	for index in range(count):
		await physics_frame
		player.velocity = Vector3(0,player.velocity.y-18.0/60.0,0)
		player.move_and_slide()

func walk_to(player: CharacterBody3D, target: Vector3, max_frames: int = 480) -> bool:
	for index in range(max_frames):
		await physics_frame
		var offset := Vector3(target.x-player.position.x,0,target.z-player.position.z)
		if offset.length()<0.18: return true
		var direction := offset.normalized()
		player.velocity.x = direction.x*4.0
		player.velocity.z = direction.z*4.0
		player.velocity.y = player.velocity.y-18.0/60.0 if not player.is_on_floor() else 0.0
		player.move_and_slide()
	print("Walk stopped at ",player.position," target ",target)
	return false

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var deadline := Time.get_ticks_msec()+30000
	while not game.building.navigation_ready:
		await process_frame
		if Time.get_ticks_msec()>deadline:
			check(false,"Navigation initializes within 30 seconds")
			quit(1)
			return
	game.set_process(false)
	game.player.set_physics_process(false)
	var p: CharacterBody3D = game.player
	await frames(3)
	check(game.phase=="menu","Main menu is the initial screen")
	check(game.building.navigation_region.navigation_mesh.get_polygon_count()>100,"Campus navigation contains usable polygons")
	var map: RID = game.building.get_world_3d().navigation_map
	var path := NavigationServer3D.map_get_path(map,Vector3(-4,0,5),Vector3(-15.5,12,0),true)
	check(path.size()>2 and path[-1].distance_to(Vector3(-15.5,12,0))<1.0,"Navigation connects the ground lobby to the upper auditorium")
	var rear_path := NavigationServer3D.map_get_path(map,Vector3(0,0,5),Vector3(0,-0.9,40),true)
	check(rear_path.size()>1 and rear_path[-1].distance_to(Vector3(0,-0.9,40))<1.0,"Navigation connects the lobby to the rear courtyard")
	game.explore_map()
	p.reset_to(Vector3(0,0.06,5),0)
	await settle(p)
	check(p.is_on_floor() and absf(p.position.y)<0.1,"Player spawns grounded at human eye height")
	check(absf(p.view_camera.position.y-1.65)<0.01,"Standing eye height is 1.65 metres")
	check(await walk_to(p,Vector3(0,0,27)),"Rear glass door opening is traversable")
	check(await walk_to(p,Vector3(0,-0.9,33)),"Rear outdoor steps are traversable")
	await settle(p)
	check(absf(p.position.y+0.9)<0.1,"Player reaches courtyard ground elevation")
	p.reset_to(Vector3(10.2,0.05,3.35),0)
	await settle(p)
	var climbed := true
	for level in range(3):
		for target in [Vector3(14.5,level*4,3.35),Vector3(14.5,level*4+2,-3.35),Vector3(17.7,level*4+2,-3.35),Vector3(17.7,level*4+4,3.35)]:
			if not await walk_to(p,target): climbed = false; break
		await settle(p,4)
		check(absf(p.position.y-(level+1)*4)<0.15,"Stair flights reach balcony level %d" % (level+1))
		if not climbed: break
	check(climbed,"All internal stair flights can be walked without jumping")
	p.reset_to(Vector3(-10.3,12.05,0),PI/2)
	await settle(p)
	check(await walk_to(p,Vector3(-15.5,12,0)),"Auditorium entrance connects to upper balcony")
	check(await walk_to(p,Vector3(-26,13.6,0)),"Auditorium central aisle is traversable")
	await settle(p,4)
	check(p.position.y>13.3,"Auditorium tier ramp climbs to the back rows")
	p.reset_to(Vector3(9.8,12.05,0),0)
	await settle(p)
	await walk_to(p,Vector3(7,12,0),90)
	check(p.position.x>8.65 and p.position.y>11.8,"Balcony rail prevents walking into the atrium void")
	game.start_match(0,1)
	for bot in game.bots: bot.set_physics_process(false)
	check(game.bots.size()==7 and p.team==0,"CT match starts with 3 teammates and 4 enemies")
	check(game.phase=="freeze" and p.money==800,"First round has freeze time and pistol-round economy")
	p.money = 5000
	check(game.buy("ak") and p.primary=="ak" and p.money==2300,"Buying a rifle equips it and charges the price")
	check(not game.buy("m4") and p.money==2300,"Unaffordable purchases leave money unchanged")
	check(game.buy("armor") and p.armor==100,"Armor purchase works")
	check(not game.buy("armor"),"Duplicate full armor purchase is rejected")
	check(game.buy("kit") and p.kit,"CT defuse kit purchase works")
	check(game.buy("he") and game.buy("flash") and game.buy("smoke"),"All three grenade types can be bought")
	check(not game.buy("he"),"Grenade inventory limit prevents duplicate purchase")
	game.buy_elapsed = 21
	check(not game.buy("ammo"),"Buying is rejected after the buy window")
	game.buy_elapsed = 0
	p.position = Vector3(40,0,40)
	check(not game.buy("ammo"),"Buying is rejected outside the spawn zone")
	game.phase = "active"
	p.reset_to(Vector3(0,0.05,3),0)
	for bot in game.bots: bot.position = Vector3(40,-0.85,40)
	var enemy: Node3D
	var ally: Node3D
	for bot in game.bots:
		if bot.team!=p.team: enemy = bot
		else: ally = bot
	enemy.position = Vector3(0,0.05,-3)
	enemy.armor = 0
	await frames(3)
	p.view_camera.look_at(enemy.position+Vector3(0,1.64,0))
	p.weapon = "ak"
	p.cooldown = 0
	p.reload_left = 0
	p.velocity = Vector3.ZERO
	var old_mag: int = p.ammunition["ak"]["mag"]
	check(p.try_fire() and p.ammunition["ak"]["mag"]==old_mag-1,"Firing consumes one round")
	check(enemy.health==0 and p.kills==1,"A real collision ray headshot kills an enemy and credits the kill")
	check(not p.try_fire(),"Weapon rate of fire blocks immediate repeated shots")
	p.ammunition["ak"] = {"mag":0,"reserve":8}
	p.start_reload()
	check(p.reload_left>0,"Reload starts on an empty magazine")
	p.finish_reload()
	check(p.ammunition["ak"]["mag"]==8 and p.ammunition["ak"]["reserve"]==0,"Reload transfers only available reserve ammo")
	ally.position = Vector3(0,0.05,-3)
	ally.health = 100
	await frames(2)
	p.view_camera.look_at(ally.position+Vector3(0,1.3,0))
	p.cooldown = 0
	p.try_fire()
	check(ally.health==100,"Friendly fire is disabled")
	ally.position = Vector3(40,-0.85,40)
	enemy.respawn(Vector3(0,-0.85,-22))
	enemy.set_physics_process(false)
	await frames(2)
	p.view_camera.look_at(enemy.position+Vector3(0,1.3,0))
	p.cooldown = 0
	p.try_fire()
	check(enemy.health==100,"Building walls stop bullets")
	enemy.position = Vector3(0,0.05,-3)
	await frames(2)
	game.grenade_explode("flash",Vector3(0,1,0),p)
	check(enemy.flash_left>0,"Flash grenade affects visible enemies")
	game.grenade_explode("he",Vector3(0,1,0),p)
	check(enemy.health<100 and enemy.health>0,"HE grenade applies radial damage")
	game.grenade_explode("smoke",Vector3(0,0,0),p)
	check(game.smoke_clouds.size()==1 and not game.has_sight(p,enemy),"Smoke blocks bot sight")
	game._clear_effects()
	p.health = 100
	p.armor = 100
	p.take_damage(50,enemy)
	check(p.health==70 and p.armor==80,"Armor absorbs part of incoming damage")
	game.start_match(1,1)
	for bot in game.bots: bot.set_physics_process(false)
	check(p.team==1 and game.bomb_carrier==p,"T player starts with the bomb")
	game.phase = "active"
	p.position = Vector3(0,0.05,0)
	p.velocity = Vector3.ZERO
	Input.action_press("interact")
	for n in range(3): game._update_bomb(1.0)
	Input.action_release("interact")
	check(game.bomb_planted,"Holding E at a bomb site plants the bomb")
	game._update_bomb(36.0)
	check(game.phase=="end" and game.score[1]==1,"Bomb explosion awards the T round")
	game._start_round()
	game.phase = "active"
	game.plant_bomb(Vector3(0,0,0))
	game.defuse_bomb()
	check(game.phase=="end" and game.score[0]==1,"Defusing awards the CT round")
	var old_money: int = p.money
	game.end_round(0,"Duplicate")
	check(game.score[0]==1 and p.money==old_money,"Round results cannot pay twice")
	game.explore_map()
	p.set_physics_process(false)
	check(game.exploring and game.bots.is_empty(),"Map exploration disables combat and removes bots")
	game.set_paused(true)
	check(paused and game.paused,"Pause stops the scene tree")
	game.set_paused(false)
	check(not paused,"Resume restores scene processing")
	game.return_to_menu()
	check(game.phase=="menu" and game.hud.menu_panel.visible,"Returning to menu restores the start screen")
	print("RESULT: ",passed," passed, ",failed," failed")
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failed==0 else 1)
