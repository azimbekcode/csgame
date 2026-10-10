extends SceneTree

var passed := 0
var failed := 0
var game: Node3D

func floor_y(level: int) -> float:
	return -1.8 if level == 0 else level*4.0

func stair_mid(level: int) -> float:
	return (floor_y(level)+floor_y(level+1))/2

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
	var path := NavigationServer3D.map_get_path(map,Vector3(-4,-1.8,5),Vector3(-12.7,12,0),true)
	check(path.size()>2 and path[-1].distance_to(Vector3(-12.7,12,0))<1.0,"Navigation connects the ground lobby to the upper auditorium")
	for side in [-1.0,1.0]:
		for level in range(3):
			var destination: Vector3 = game.building.stair_point(side,0,18.15,stair_mid(level))
			var stair_path := NavigationServer3D.map_get_path(map,Vector3(0,-1.8,-13),destination,true)
			check(stair_path.size()>2 and stair_path[-1].distance_to(destination)<0.4,"Bot navigation reaches front stair side %d turning landing %d" % [int(side),level])
	var rear_path := NavigationServer3D.map_get_path(map,Vector3(0,-1.8,5),Vector3(0,-0.9,40),true)
	check(rear_path.size()>1 and rear_path[-1].distance_to(Vector3(0,-0.9,40))<1.0,"Navigation connects the lobby to the rear courtyard")
	game.explore_map()
	check(game.building.lift.position.x<0,"Lift is left when entering from the rear")
	check(game.building.find_children("BrownRoomDoor_*","Node3D",false,false).size()==20,"All twenty rooms have brown timber doors")
	check(game.building.find_children("TieredLectureRoom*","Node3D",false,false).size()==20,"All twenty rooms have tiered lecture seating")
	var guidance: Array[Node] = game.building.find_children("GroundGuidance*","Node3D",false,false)
	check(guidance.size()==45,"Rear entrance has its complete tactile guidance strip")
	var guidance_grounded := true
	for node in guidance: guidance_grounded = guidance_grounded and absf(node.position.y-(-1.8+0.025))<0.001
	check(guidance_grounded,"Yellow guidance ribs rest on the lowered floor")
	for side in [-1,1]:
		var bay: Node3D = game.building.get_node("MarkedStairBay_%d" % side)
		check(bay.find_children("StairRailing*","Node3D",false,false).size()==36,"Stair bay %d has joined flight and landing railings" % side)
	check(game.building.stair_surfaces.size()>12,"Controller can identify actual tread dimensions on all stair flights")
	p.reset_to(Vector3(0,-1.74,5),0)
	await settle(p)
	check(p.is_on_floor() and absf(p.position.y+1.8)<0.1,"Player spawns grounded at human eye height")
	check(absf(p.view_camera.position.y-1.65)<0.01,"Standing eye height is 1.65 metres")
	check(await walk_to(p,Vector3(0,-1.8,20.8)),"Rear glass door opening is traversable")
	check(await walk_to(p,Vector3(0,-0.9,25.5)),"Rear outdoor steps are traversable")
	await settle(p)
	check(absf(p.position.y+0.9)<0.1,"Player reaches courtyard ground elevation")
	for side in [-1.0,1.0]:
		p.reset_to(game.building.stair_point(side,0,9.4,-1.75),0)
		await settle(p)
		var climbed := true
		for level in range(3):
			for target in [game.building.stair_point(side,0,12.7,floor_y(level)),game.building.stair_point(side,-1.05,13.8,floor_y(level)),game.building.stair_point(side,-1.05,18.15,stair_mid(level)),game.building.stair_point(side,1.05,18.15,stair_mid(level)),game.building.stair_point(side,1.05,12.7,floor_y(level+1)),game.building.stair_point(side,0,12.7,floor_y(level+1)),game.building.stair_point(side,0,9.4,floor_y(level+1))]:
				if not await walk_to(p,target,180): climbed = false; break
			await settle(p,4)
			check(absf(p.position.y-floor_y(level+1))<0.15,"Front stair side %d reaches level %d" % [int(side),level+1])
			if not climbed: break
		check(climbed,"Front stair side %d climbs all floors without jumping" % int(side))
		var descended := climbed
		if climbed:
			for level in [2,1,0]:
				for target in [game.building.stair_point(side,0,12.7,floor_y(level+1)),game.building.stair_point(side,1.05,13.8,floor_y(level+1)),game.building.stair_point(side,1.05,18.15,stair_mid(level)),game.building.stair_point(side,-1.05,18.15,stair_mid(level)),game.building.stair_point(side,-1.05,12.7,floor_y(level)),game.building.stair_point(side,0,12.7,floor_y(level)),game.building.stair_point(side,0,9.4,floor_y(level))]:
					if not await walk_to(p,target,180): descended = false; break
				await settle(p,4)
				check(absf(p.position.y-floor_y(level))<0.15,"Front stair side %d descends to level %d" % [int(side),level])
		check(descended,"Front stair side %d descends all floors without jumping" % int(side))
	p.reset_to(Vector3(0,-1.75,-13),0)
	await settle(p)
	check(await walk_to(p,Vector3(0,-1.8,-21.4)),"Sunken front vestibule connects to ground-floor lobby")
	check(await walk_to(p,Vector3(5,-0.9,-21.4)),"Ground-floor front door connects to courtyard by side steps")
	await settle(p)
	check(absf(p.position.y+0.9)<0.15,"Front side stairs reach courtyard elevation")
	check(await walk_to(p,Vector3(0,-1.8,-21.4)),"Front side stairs descend into the lower doorway landing")
	await settle(p)
	check(absf(p.position.y+1.8)<0.15,"Front doorway landing is below the courtyard")
	for z in [-20.5,-19.5,-18.0,-16.0,-14.0,-12.0,-8.0]:
		check(await walk_to(p,Vector3(0,-1.8,z)),"Flat entrance is walkable through vestibule at z=%.1f" % z)
		await settle(p,3)
		check(absf(p.position.y+1.8)<0.08,"Entrance stays level without an indoor stair at z=%.1f" % z)
	var clear_ray := PhysicsRayQueryParameters3D.create(Vector3(0,-0.9,-21.4),Vector3(0,-0.9,-10))
	check(p.get_world_3d().direct_space_state.intersect_ray(clear_ray).is_empty(),"No slab or barrier crosses the front doorway at body height")
	p.reset_to(Vector3(-9.5,12.05,0),PI/2)
	await settle(p)
	check(await walk_to(p,Vector3(-12.7,12,0)),"Auditorium entrance connects to upper balcony")
	check(await walk_to(p,Vector3(-18,12.54,0)),"Auditorium central aisle is traversable")
	await settle(p,4)
	check(p.position.y>12.4,"Auditorium tier ramp climbs to the back rows")
	p.reset_to(Vector3(8.5,12.05,0),0)
	await settle(p)
	await walk_to(p,Vector3(5,12,0),90)
	check(p.position.x>6.65 and p.position.y>11.8,"Balcony rail prevents walking into the atrium void")
	check(game.building.FLOOR_COUNT==4,"Building has levels 0, 1, 2 and 3")
	var stair_walls := true
	var stair_guards := true
	for level in range(4):
		for side in [-1.0,1.0]:
			var wall_query := PhysicsRayQueryParameters3D.create(game.building.stair_point(side,1.8,15,floor_y(level)+1),game.building.stair_point(side,2.3,15,floor_y(level)+1))
			stair_walls = stair_walls and not p.get_world_3d().direct_space_state.intersect_ray(wall_query).is_empty()
		if level>0:
			p.reset_to(Vector3(14,floor_y(level)+0.05,0),0)
			await settle(p)
			check(absf(p.position.y-floor_y(level))<0.15,"Removed east stairwell has a solid floor on level %d" % level)
			for side in [-1.0,1.0]:
				var guard_query := PhysicsRayQueryParameters3D.create(game.building.stair_point(side,0,13.2,floor_y(level)+0.55),game.building.stair_point(side,0,13.8,floor_y(level)+0.55))
				stair_guards = stair_guards and not p.get_world_3d().direct_space_state.intersect_ray(guard_query).is_empty()
	check(stair_walls,"Both front stair bays have continuous room partitions on all floors")
	check(stair_guards,"Front stair landing guards physically block accidental falls")
	for level in range(4):
		for d in [0.0,22.5,337.5]:
			var a := deg_to_rad(d)
			var origin := Vector3(cos(a)*10.4,floor_y(level)+1.0,sin(a)*10.4)
			var end := Vector3(cos(a)*11.7,floor_y(level)+1.0,sin(a)*11.7)
			check(not p.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,end)).is_empty(),"Former stair-side room wall is closed on level %d at %.1f degrees" % [level,d])
	for entry in game.building.room_entries:
		var start := Vector3(entry.x,0,entry.z).normalized()*9.4
		start.y = entry.y
		p.reset_to(start,0)
		await settle(p,3)
		check(await walk_to(p,entry),"Room doorway is walkable at %.1f, %.1f, %.1f" % [entry.x,entry.y,entry.z])
	for side in [-1.0,1.0]:
		p.reset_to(Vector3(side*9.4,-0.85,29.4),0)
		await settle(p)
		check(await walk_to(p,Vector3(side*9.4,1.4,21.6)),"Rear lower flight reaches the turning landing")
		check(absf(p.position.y-1.4)<0.15,"Rear turn landing is at intermediate height")
		check(await walk_to(p,Vector3(side*7.8,1.6,21.6)) and await walk_to(p,Vector3(side*2.4,4,21.6)),"Rear side %d stair reaches shared first-floor landing" % int(side))
		check(absf(p.position.y-4)<0.15,"Rear upper entrance is on level 1")
		check(await walk_to(p,Vector3(0,4,21.0)) and await walk_to(p,Vector3(0,4,18)),"Raised rear door connects to interior")
	p.reset_to(Vector3(0,-0.85,-33.5),0)
	await settle(p)
	check(await walk_to(p,Vector3(0,4,-21.5)),"Wide front stairs are climbable without jumping")
	check(await walk_to(p,Vector3(0,4,-18)),"Front portal opens into level 1")
	# Exercise the real controller, including stair head/weapon movement.
	p.reset_to(Vector3(0,-0.85,-32.5),PI)
	await settle(p)
	p.set_physics_process(true)
	Input.action_press("forward")
	var up_offset := 0.0
	for frame in range(75):
		await physics_frame
		up_offset = maxf(up_offset,absf(p.stair_view_offset))
	Input.action_release("forward")
	check(up_offset>0.04 and p.position.y>-0.1,"Ascending stairs produces tread-paced camera motion")
	p.rotation.y = 0
	Input.action_press("forward")
	var down_offset := 0.0
	for frame in range(60):
		await physics_frame
		down_offset = maxf(down_offset,absf(p.stair_view_offset))
	Input.action_release("forward")
	check(down_offset>0.02,"Descending stairs produces tread-paced camera motion")
	await frames(35)
	check(p.stair_amount<0.01,"Stair motion settles when the player stops")
	p.set_physics_process(false)
	var lift: Node3D = game.building.lift
	p.reset_to(lift.to_global(Vector3(-2.4,-1.75,0)),0)
	await frames(50)
	check(lift.door_open[0]>0.98,"Approaching a present cabin automatically opens paired doors")
	check(lift.gates[0].collision_layer==0,"An open lift entrance is physically walkable")
	check(lift.gates[1].collision_layer==1 and lift.door_open[1]==0,"An absent cabin leaves the other landing closed")
	check(lift.find_child("CallButton_0",true,false)!=null,"Landing has a visible physical call button")
	check(lift.cabin_panels.size()==2 and lift.cabin_gate.collision_layer==0,"Cabin has paired sliding doors that open at a landing")
	for height in [2.0,7.2,11.2]:
		var from := lift.to_global(Vector3(0,height,0))
		var to := lift.to_global(Vector3(-2,height,0))
		check(not p.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1)).is_empty(),"Lift shaft is enclosed between floors at %.1f" % height)
	p.reset_to(lift.global_position+Vector3(0,-1.74,0),0)
	await settle(p)
	check(lift.contains_actor(p),"Player can enter physical lift cabin")
	for frame in range(3): await process_frame
	var mirror: Node3D = lift.cabin.get_node("CabinMirror")
	var mirror_normal: Vector3 = mirror.global_basis*Vector3.LEFT
	var eye_distance: float = mirror_normal.dot(p.view_camera.global_position-mirror.global_position)
	var reflected_distance: float = mirror_normal.dot(mirror.camera.global_position-mirror.global_position)
	check(absf(eye_distance+reflected_distance)<0.02 and mirror.viewport.world_3d==p.get_world_3d(),"Lift mirror reflects the live eye position in the shared scene")
	check(is_instance_valid(p.reflection_body) and p.reflection_body.hips.size()==2 and (p.view_camera.cull_mask&2)==0 and (mirror.camera.cull_mask&2)!=0,"Player body appears in the mirror without obstructing first-person view")
	for floor_index in [1,2,3,0]:
		check(lift.request_floor(floor_index,p),"Lift accepts destination %d" % floor_index)
		check(lift.cabin_gate.collision_layer==1,"Cabin entrance is secured during travel")
		var limit := Time.get_ticks_msec()+15000
		while lift.moving and Time.get_ticks_msec()<limit: await physics_frame
		check(not lift.moving and absf(p.position.y-floor_y(floor_index))<0.15,"Lift carries player to level %d" % floor_index)
		check(not p.lift_riding,"Lift releases movement after arrival")
		check(await walk_to(p,Vector3(-1.4,floor_y(floor_index),16.2)),"Lift exit is walkable on level %d" % floor_index)
		check(await walk_to(p,lift.global_position+Vector3(0,floor_y(floor_index),0)),"Lift can be reentered on level %d" % floor_index)
	# Calling the empty lift must not carry a player standing on the landing.
	p.reset_to(Vector3(-1.7,-1.75,16.2),0)
	check(lift.request_floor(2),"Empty lift can be dispatched")
	while lift.moving: await physics_frame
	check(not p.lift_riding and p.position.y<0.2,"Calling lift leaves the waiting player on the landing")
	check(lift.prompt(p).contains("chaqirish tugmasi"),"Absent cabin offers the landing call-button prompt")
	lift.interact(p)
	check(lift.moving and lift.target_floor==0 and lift.waiting_floor==0,"Call button requests the caller's own floor")
	check(lift.gates[0].collision_layer==1,"Landing stays blocked while a called cabin travels")
	while lift.moving: await physics_frame
	await frames(50)
	check(lift.current_floor==0 and lift.door_open[0]>0.98,"Called cabin arrives and opens automatically")
	p.reset_to(lift.to_global(Vector3(-1.3,-1.75,0)),0)
	lift.hold_open = 0
	await frames(50)
	check(lift.door_open[0]>0.98,"Occupied doorway keeps lift doors open")
	p.reset_to(Vector3(0,-1.75,5),0)
	await frames(230)
	check(lift.door_open[0]<0.01 and lift.gates[0].collision_layer==1,"Unattended lift closes its doors after the hold time")
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
	p.reset_to(Vector3(0,-1.75,3),0)
	for bot in game.bots: bot.position = Vector3(40,-0.85,40)
	var enemy: Node3D
	var ally: Node3D
	for bot in game.bots:
		if bot.team!=p.team: enemy = bot
		else: ally = bot
	enemy.position = Vector3(0,-1.75,-3)
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
	ally.position = Vector3(0,-1.75,-3)
	ally.health = 100
	await frames(2)
	p.view_camera.look_at(ally.position+Vector3(0,1.3,0))
	p.cooldown = 0
	p.try_fire()
	check(ally.health==100,"Friendly fire is disabled")
	ally.position = Vector3(40,-0.85,40)
	enemy.respawn(Vector3(7,-0.85,-23))
	enemy.set_physics_process(false)
	await frames(2)
	p.view_camera.look_at(enemy.position+Vector3(0,1.3,0))
	p.cooldown = 0
	p.try_fire()
	check(enemy.health==100,"Building walls stop bullets")
	enemy.position = Vector3(0,-1.75,-3)
	await frames(2)
	game.grenade_explode("flash",Vector3(0,-0.8,0),p)
	check(enemy.flash_left>0,"Flash grenade affects visible enemies")
	game.grenade_explode("he",Vector3(0,-0.8,0),p)
	check(enemy.health<100 and enemy.health>0,"HE grenade applies radial damage")
	game.grenade_explode("smoke",Vector3(0,-1.8,0),p)
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
	p.position = Vector3(0,-1.75,0)
	p.velocity = Vector3.ZERO
	Input.action_press("interact")
	for n in range(3): game._update_bomb(1.0)
	Input.action_release("interact")
	check(game.bomb_planted,"Holding E at a bomb site plants the bomb")
	game._update_bomb(36.0)
	check(game.phase=="end" and game.score[1]==1,"Bomb explosion awards the T round")
	game._start_round()
	game.phase = "active"
	game.plant_bomb(Vector3(0,-1.8,0))
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
