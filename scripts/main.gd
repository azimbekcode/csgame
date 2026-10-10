extends Node3D

const PLAYER = preload("res://scripts/player.gd")
const MAP = preload("res://scripts/building_map.gd")
const BOT = preload("res://scripts/bot.gd")
const HUD = preload("res://scripts/hud.gd")
const WEAPONS = preload("res://scripts/weapons.gd")
const GRENADE = preload("res://scripts/grenade.gd")
const SITES := [Vector3(0,0,0), Vector3(0,-0.9,36)]
const SPAWNS := [Vector3(-4,0.05,5.5), Vector3(0,-0.85,41)]

var player: CharacterBody3D
var building: Node3D
var hud: CanvasLayer
var bots: Array[Node3D] = []
var phase := "menu"
var exploring := false
var paused := false
var round_number := 0
var score := [0,0]
var clock := 5.0
var buy_elapsed := 0.0
var attack_site := 0
var bot_delay := 0.28
var bot_spread := 0.025
var bomb_carrier: Node3D
var bomb_planted := false
var bomb_position := Vector3.ZERO
var bomb_left := 35.0
var bomb_node: Node3D
var bomb_dropped := false
var interact_progress := 0.0
var beep_left := 0.0
var smoke_clouds: Array[Dictionary] = []
var sounds: Dictionary = {}
var last_round_message := ""
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	_bind_inputs()
	for kind in ["shot","reload","step"]: sounds[kind] = WEAPONS.sound(kind)
	building = Node3D.new()
	building.name = "BuildingMap"
	building.set_script(MAP)
	add_child(building)
	_spawn_player()
	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(HUD)
	add_child(hud)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.reset_to(Vector3(0,0.08,6),0)
	player.view_camera.look_at(Vector3(0,5.3,-3))


func _bind_inputs() -> void:
	var keys := {"left":KEY_A,"right":KEY_D,"forward":KEY_W,"back":KEY_S,"jump":KEY_SPACE,"crouch":KEY_CTRL,"walk":KEY_SHIFT,"interact":KEY_E,"scoreboard":KEY_TAB}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = keys[action]
			InputMap.action_add_event(action,event)
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire",event)


func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PLAYER)
	player.floor_snap_length = 0.35
	player.floor_constant_speed = true
	player.safe_margin = 0.02
	player.collision_layer = 2
	player.collision_mask = 3
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	collision.position.y = 0.9
	player.add_child(collision)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position.y = 1.65
	camera.fov = 80
	camera.far = 150
	camera.current = true
	player.add_child(camera)
	add_child(player)


func input_locked() -> bool:
	return phase in ["menu","finished","end"] or paused or (is_instance_valid(hud) and hud.shop_open)


func can_fire() -> bool:
	return phase == "active" and not exploring and not paused


func start_match(team_choice: int = 0, difficulty: int = 1) -> void:
	if not building.navigation_ready:
		hud.message("Xarita tayyorlanyapti. Bir oz kuting.")
		return
	_clear_bots()
	exploring = false
	score = [0,0]
	round_number = 0
	player.team = team_choice
	player.money = 800
	player.kills = 0
	player.deaths = 0
	player.health = 0
	bot_delay = [0.48,0.28,0.08][difficulty]
	bot_spread = [0.045,0.025,0.008][difficulty]
	for team in range(2):
		for number in range(3 if team == player.team else 4):
			var bot := CharacterBody3D.new()
			bot.name = "Bot_%d_%d" % [team,number]
			bot.set_script(BOT)
			bot.team = team
			bot.actor_name = ("CT" if team == 0 else "T") + "-%d" % (number + 1)
			add_child(bot)
			bots.append(bot)
	hud.close_panels()
	_start_round()


func _clear_bots() -> void:
	for bot in bots:
		if is_instance_valid(bot):
			remove_child(bot)
			bot.queue_free()
	bots.clear()


func _start_round() -> void:
	get_tree().paused = false
	paused = false
	_clear_effects()
	_clear_bomb()
	bomb_dropped = false
	bomb_planted = false
	bomb_left = 35.0
	interact_progress = 0
	round_number += 1
	attack_site = round_number % 2
	phase = "freeze"
	clock = 5.0
	buy_elapsed = 0
	last_round_message = ""
	player.respawn(SPAWNS[player.team], PI if player.team == 1 else 0.0)
	var indices := [0,0]
	for bot in bots:
		indices[bot.team] += 1
		bot.respawn(SPAWNS[bot.team] + Vector3((indices[bot.team]-2)*1.4,0,1.7))
	bomb_carrier = player if player.team == 1 else _first_alive(1)
	hud.shop_open = false
	hud.close_panels()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.message("%d-raund. B — qurol xaridi. %s" % [round_number,"Bomba sizda: A yoki B nuqtada E ni tuting." if player.team == 1 else "A va B nuqtalarini himoya qiling."])


func _process(delta: float) -> void:
	if phase in ["menu","finished"] or paused:
		return
	if exploring:
		return
	buy_elapsed += delta
	if phase == "freeze":
		clock -= delta
		if clock <= 0: phase = "active"; clock = 115.0
	elif phase == "active":
		clock -= delta
		_update_bomb(delta)
		if clock <= 0 and not bomb_planted: end_round(0,"Vaqt tugadi — CT g‘alaba")
		_check_round_end()
	elif phase == "end":
		clock -= delta
		if clock <= 0:
			if maxi(score[0],score[1]) >= 5:
				phase = "finished"
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				hud.show_result(last_round_message)
			else: _start_round()
	for cloud in smoke_clouds:
		cloud["left"] -= delta
		if cloud["left"] <= 0 and is_instance_valid(cloud["node"]): cloud["node"].queue_free()
	smoke_clouds = smoke_clouds.filter(func(cloud): return cloud["left"] > 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B and phase in ["freeze","active"] and not exploring:
			hud.toggle_shop()


func can_buy() -> bool:
	return not exploring and player.health > 0 and phase in ["freeze","active"] and buy_elapsed < 20.0 and player.global_position.distance_to(player.round_spawn) < 12.0


func buy(id: String) -> bool:
	if not can_buy(): hud.message("Xarid faqat dastlabki 20 soniyada, boshlanish joyida."); return false
	var prices := {"armor":650,"kit":400,"ammo":100}
	var price: int = prices[id] if id in prices else int(WEAPONS.DATA[id]["price"])
	if player.money < price: hud.message("Pul yetarli emas."); return false
	if id == "kit" and (player.team != 0 or player.kit): return false
	if id in ["he","flash","smoke"] and player.grenades[id] >= 1: return false
	if id == "armor" and player.armor == 100: return false
	player.money -= price
	match id:
		"armor": player.armor = 100
		"kit": player.kit = true
		"ammo":
			for key in player.ammunition: player.ammunition[key]["reserve"] = int(WEAPONS.DATA[key]["reserve"])
		"he", "flash", "smoke": player.grenades[id] = 1
		_:
			player.primary = id
			player.fill_ammunition(id)
			player.equip(id)
	hud.message("Xarid qilindi: %s" % id)
	return true


func _first_alive(team_value: int) -> Node3D:
	for actor in get_tree().get_nodes_in_group("combatants"):
		if actor.team == team_value and actor.health > 0: return actor
	return null


func _check_round_end() -> void:
	if phase != "active": return
	if _first_alive(0) == null: end_round(1,"T g‘alaba — CT jamoasi yo‘q qilindi")
	elif _first_alive(1) == null and not bomb_planted: end_round(0,"CT g‘alaba — T jamoasi yo‘q qilindi")


func end_round(winner: int, reason: String) -> void:
	if phase not in ["active","freeze"]: return
	phase = "end"
	clock = 6.0
	score[winner] += 1
	last_round_message = reason
	hud.shop_open = false
	hud.close_panels()
	hud.message(reason,6.0)
	for actor in get_tree().get_nodes_in_group("combatants"):
		actor.money = mini(16000,actor.money + (3250 if actor.team == winner else 1400))


func on_death(victim: Node3D, attacker: Node3D) -> void:
	if is_instance_valid(attacker) and attacker != victim and attacker.team != victim.team:
		attacker.kills += 1
		attacker.money = mini(16000,attacker.money + 300)
	var source: String = attacker.actor_name if is_instance_valid(attacker) else "Muhit"
	hud.kill_notice("%s  >  %s" % [source,victim.actor_name])
	if victim == bomb_carrier and not bomb_planted:
		bomb_carrier = null
		bomb_dropped = true
		bomb_position = victim.global_position
		_show_bomb(bomb_position)
	if victim == player:
		hud.shop_open = false
		hud.close_panels()
		hud.message("Siz yiqildingiz. Raund tugagach qaytasiz. Tab — hisob.",5.0)
	_check_round_end()


func bot_objective(bot: Node3D) -> Vector3:
	if bomb_planted:
		return bomb_position + (Vector3(0.8,0,0.8) if bot.team == 0 else Vector3(3,0,2))
	if bot.team == 1 and bomb_dropped: return bomb_position
	var site: Vector3 = SITES[attack_site]
	var index: int = bots.find(bot)
	return site + Vector3((index%3-1)*1.2,0,(index%2)*1.0)


func bot_interact(bot: Node3D, delta: float, enemy_visible: bool) -> bool:
	if bomb_planted and bot.team == 0 and bot.global_position.distance_to(bomb_position) < 2.3:
		if enemy_visible and bomb_left > 8: bot.objective_progress = 0; return false
		bot.objective_progress += delta
		if bot.objective_progress >= (5.0 if bot.kit else 10.0): defuse_bomb()
		return true
	if bot == bomb_carrier and bot.global_position.distance_to(SITES[attack_site]) < 2.5:
		if enemy_visible: bot.objective_progress = 0; return false
		bot.objective_progress += delta
		if bot.objective_progress >= 3.0: plant_bomb(bot.global_position)
		return true
	bot.objective_progress = 0
	return false


func _update_bomb(delta: float) -> void:
	if bomb_dropped:
		for actor in get_tree().get_nodes_in_group("combatants"):
			if actor.team == 1 and actor.health > 0 and actor.global_position.distance_to(bomb_position) < 1.8:
				bomb_carrier = actor
				bomb_dropped = false
				_clear_bomb()
				break
	if bomb_planted:
		bomb_left -= delta
		beep_left -= delta
		if beep_left <= 0:
			beep_left = maxf(0.15,bomb_left/30.0)
			play_sound("reload",bomb_position,-12.0)
		if bomb_left <= 0:
			_explosion_visual(bomb_position)
			end_round(1,"Bomba portladi — T g‘alaba")
	if player.health <= 0 or input_locked(): interact_progress = 0; return
	var eligible := false
	var needed := 3.0
	if bomb_planted and player.team == 0:
		eligible = player.global_position.distance_to(bomb_position) < 2.5
		needed = 5.0 if player.kit else 10.0
	elif bomb_carrier == player and not bomb_planted:
		for site in SITES:
			if player.global_position.distance_to(site) < 3.2: eligible = true
	if eligible and Input.is_action_pressed("interact") and player.velocity.length() < 0.4:
		interact_progress += delta
		if interact_progress >= needed:
			if bomb_planted: defuse_bomb()
			else: plant_bomb(player.global_position)
	else: interact_progress = 0


func plant_bomb(point: Vector3) -> void:
	if phase != "active" or bomb_planted: return
	bomb_position = point
	bomb_planted = true
	bomb_dropped = false
	bomb_left = 35
	beep_left = 0
	interact_progress = 0
	_show_bomb(point)
	hud.message("Bomba o‘rnatildi! CT: yonida E ni tutib zararsizlantiring.",5.0)


func defuse_bomb() -> void:
	if not bomb_planted or phase != "active": return
	bomb_planted = false
	_clear_bomb()
	end_round(0,"Bomba zararsizlantirildi — CT g‘alaba")


func _show_bomb(point: Vector3) -> void:
	_clear_bomb()
	bomb_node = Node3D.new()
	bomb_node.position = point + Vector3(0,0.12,0)
	WEAPONS.box(bomb_node,Vector3.ZERO,Vector3(0.28,0.16,0.22),WEAPONS.material(Color("70684e")))
	WEAPONS.box(bomb_node,Vector3(0,0.09,0),Vector3(0.1,0.02,0.08),WEAPONS.material(Color("d44036")))
	add_child(bomb_node)


func _clear_bomb() -> void:
	if is_instance_valid(bomb_node):
		remove_child(bomb_node)
		bomb_node.queue_free()
	bomb_node = null


func has_sight(observer: Node3D, target: Node3D) -> bool:
	var from := observer.global_position + Vector3(0,1.5,0)
	var to := target.global_position + Vector3(0,1.25,0)
	for cloud in smoke_clouds:
		if Geometry3D.get_closest_point_to_segment(cloud["position"],from,to).distance_to(cloud["position"]) < 4.0: return false
	var query := PhysicsRayQueryParameters3D.create(from,to,3,[observer.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit["collider"] == target


func fire(actor: Node3D, origin: Vector3, direction: Vector3, id: String) -> void:
	if not can_fire(): return
	var definition: Dictionary = WEAPONS.DATA[id]
	var spread: float = definition["spread"]
	if actor == player:
		if player.scoped: spread *= 0.15
		spread += Vector2(player.velocity.x,player.velocity.z).length() * 0.002
	else: spread += bot_spread
	var pellets := 8 if id == "shotgun" else 1
	for pellet in range(pellets):
		var aim := (direction + Vector3(rng.randf_range(-spread,spread),rng.randf_range(-spread,spread),rng.randf_range(-spread,spread))).normalized()
		var endpoint := origin + aim * (2.2 if id == "knife" else 120.0)
		var query := PhysicsRayQueryParameters3D.create(origin,endpoint,3,[actor.get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			endpoint = hit["position"]
			var target: Node3D = hit["collider"]
			if target.has_method("take_damage"):
				var headshot := endpoint.y - target.global_position.y > 1.48
				var damage := int(definition["damage"]) * (3 if headshot else 1)
				if id != "knife": damage = maxi(1,int(damage * maxf(0.72,1.0-origin.distance_to(endpoint)/180.0)))
				target.take_damage(damage,actor)
				if actor == player and target.team != player.team: hud.hit_left = 0.18
			else: _impact(endpoint)
		if id != "knife": _tracer(origin + aim * 0.45,endpoint)
	play_sound("shot" if id != "knife" else "step",origin,-9.0 if actor == player else -15.0)
	if actor == player and id != "knife":
		var flash := OmniLight3D.new()
		flash.position = origin + direction * 0.5
		flash.light_color = Color("ffc36d")
		flash.light_energy = 2
		flash.omni_range = 3
		flash.add_to_group("transient")
		add_child(flash)
		get_tree().create_timer(0.05,false).timeout.connect(flash.queue_free)


func _tracer(from: Vector3, to: Vector3) -> void:
	if from.distance_to(to) < 0.01: return
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.006
	mesh.bottom_radius = 0.006
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 4
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var mat := WEAPONS.material(Color("ffd294"))
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	instance.material_override = mat
	instance.position = (from+to)/2
	instance.quaternion = Quaternion(Vector3.UP,(to-from).normalized())
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.add_to_group("transient")
	add_child(instance)
	get_tree().create_timer(0.07,false).timeout.connect(instance.queue_free)


func _impact(point: Vector3) -> void:
	var particle := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.035
	mesh.height = 0.07
	particle.mesh = mesh
	particle.material_override = WEAPONS.material(Color("e9c88c"))
	particle.position = point
	particle.add_to_group("transient")
	add_child(particle)
	get_tree().create_timer(0.14,false).timeout.connect(particle.queue_free)


func play_sound(kind: String, point: Vector3, volume: float) -> void:
	var audio := AudioStreamPlayer3D.new()
	audio.stream = sounds.get(kind,sounds["shot"])
	audio.position = point
	audio.volume_db = volume
	audio.max_distance = 48
	audio.add_to_group("transient")
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()


func throw_grenade(actor: Node3D, kind: String, point: Vector3, direction: Vector3) -> void:
	var grenade := RigidBody3D.new()
	grenade.set_script(GRENADE)
	grenade.game = self
	grenade.kind = kind
	grenade.owner_actor = actor
	grenade.position = point + direction * 0.55
	grenade.add_to_group("transient")
	add_child(grenade)
	grenade.linear_velocity = direction * 15.0 + Vector3(0,3.0,0)
	grenade.angular_velocity = Vector3(4,2,1)


func grenade_explode(kind: String, point: Vector3, actor: Node3D) -> void:
	if phase != "active": return
	if kind == "smoke":
		var cloud := Node3D.new()
		cloud.position = point
		cloud.add_to_group("transient")
		add_child(cloud)
		var mat := WEAPONS.material(Color(0.65,0.69,0.7,0.38))
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for number in range(7):
			var mesh := SphereMesh.new()
			mesh.radius = 2.4
			mesh.height = 4.8
			var sphere := MeshInstance3D.new()
			sphere.mesh = mesh
			sphere.position = Vector3(rng.randf_range(-1.5,1.5),1.8,rng.randf_range(-1.5,1.5))
			sphere.material_override = mat
			sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(sphere)
		smoke_clouds.append({"node":cloud,"position":point+Vector3(0,1.8,0),"left":14.0})
		return
	_explosion_visual(point)
	for target in get_tree().get_nodes_in_group("combatants"):
		if target.health <= 0: continue
		var eye: Vector3 = target.global_position + Vector3(0,1.5,0)
		var distance := eye.distance_to(point)
		if distance > (16.0 if kind == "flash" else 8.0): continue
		var query := PhysicsRayQueryParameters3D.create(point+Vector3(0,0.15,0),eye,1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		if kind == "he": target.take_damage(int(105.0*(1.0-distance/8.0)),actor)
		elif kind == "flash":
			var duration := 4.0*(1.0-distance/18.0)
			if target == player and (-player.view_camera.global_basis.z).dot((point-eye).normalized()) < 0.4: duration *= 0.3
			target.flash_left = maxf(target.flash_left,duration)


func _explosion_visual(point: Vector3) -> void:
	var flash := OmniLight3D.new()
	flash.position = point + Vector3(0,0.5,0)
	flash.light_color = Color("ffae62")
	flash.light_energy = 6.0
	flash.omni_range = 12
	flash.add_to_group("transient")
	add_child(flash)
	get_tree().create_timer(0.25,false).timeout.connect(flash.queue_free)
	play_sound("shot",point,-2.0)


func _clear_effects() -> void:
	for node in get_tree().get_nodes_in_group("transient"): node.queue_free()
	smoke_clouds.clear()


func explore_map() -> void:
	_clear_bots()
	_clear_effects()
	_clear_bomb()
	get_tree().paused = false
	paused = false
	exploring = true
	phase = "active"
	player.health = 100
	player.respawn(Vector3(0,0.05,5),0)
	hud.close_panels()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.message("Xaritani ko‘rish: F1 atrium / F2 orqa kirish / F3 auditoriya / F4 yuqori balkon",8.0)


func explore_teleport(key: int) -> void:
	match key:
		KEY_F1: player.reset_to(Vector3(0,0.05,5),0)
		KEY_F2: player.reset_to(Vector3(0,-0.85,27),PI)
		KEY_F3: player.reset_to(Vector3(-12.7,12.05,0),PI/2)
		KEY_F4: player.reset_to(Vector3(8.5,12.05,0),PI/2)


func set_paused(value: bool) -> void:
	if phase == "menu": return
	paused = value
	get_tree().paused = value
	hud.shop_open = false
	hud.pause_panel.visible = value
	hud.shop_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED


func return_to_menu() -> void:
	get_tree().paused = false
	paused = false
	exploring = false
	phase = "menu"
	_clear_bots()
	_clear_effects()
	_clear_bomb()
	player.health = 100
	player.collision_layer = 2
	player.collision_mask = 3
	player.reset_to(Vector3(0,0.08,6),0)
	player.view_camera.look_at(Vector3(0,5.3,-3))
	hud.close_panels()
	hud.menu_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
