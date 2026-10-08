extends CharacterBody3D

const WEAPONS = preload("res://scripts/weapons.gd")
var team := 1
var actor_name := "Bot"
var health := 100
var armor := 0
var money := 800
var kills := 0
var deaths := 0
var kit := false
var weapon := "pistol"
var cooldown := 0.0
var reload_left := 0.0
var magazine := 12
var flash_left := 0.0
var objective_progress := 0.0
var decision_timer := 0.0
var target: Node3D
var agent: NavigationAgent3D
var model: Node3D
var game: Node3D
var objective := Vector3.ZERO
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	game = get_parent()
	rng.seed = hash(actor_name)
	add_to_group("combatants")
	add_to_group("bots")
	collision_layer = 2
	collision_mask = 3
	floor_snap_length = 0.35
	floor_constant_speed = true
	safe_margin = 0.02
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	agent = NavigationAgent3D.new()
	agent.path_desired_distance = 0.55
	agent.path_height_offset = 0.15
	agent.target_desired_distance = 0.8
	add_child(agent)
	_make_model()


func _make_model() -> void:
	if is_instance_valid(model):
		remove_child(model)
		model.queue_free()
	model = Node3D.new()
	add_child(model)
	var uniform := WEAPONS.material(Color("345b7e") if team == 0 else Color("b18d5e"))
	var dark := WEAPONS.material(Color("242c35"))
	var skin := WEAPONS.material(Color("bf967c"))
	WEAPONS.box(model, Vector3(0,1.13,0), Vector3(0.49,0.65,0.27), uniform)
	WEAPONS.box(model, Vector3(0,1.15,-0.15), Vector3(0.38,0.44,0.06), dark)
	WEAPONS.box(model, Vector3(0,1.68,0), Vector3(0.27,0.3,0.26), skin)
	WEAPONS.box(model, Vector3(0,1.83,0), Vector3(0.3,0.1,0.29), dark)
	for side in [-1.0,1.0]:
		WEAPONS.box(model, Vector3(side*0.13,0.42,0), Vector3(0.18,0.78,0.2), uniform)
		WEAPONS.box(model, Vector3(side*0.13,0.08,-0.045), Vector3(0.2,0.16,0.29), dark)
		WEAPONS.box(model, Vector3(side*0.31,1.15,-0.12), Vector3(0.14,0.46,0.2), uniform)
	var gun := WEAPONS.make_model(weapon)
	gun.position = Vector3(0.22,1.22,-0.26)
	model.add_child(gun)


func respawn(point: Vector3) -> void:
	var dead := health <= 0
	health = 100
	if dead: armor = 0
	if money >= 2700:
		weapon = "ak" if team == 1 else "m4"
		var cost: int = WEAPONS.DATA[weapon]["price"]
		if money < cost: weapon = "mp5"; cost = 1500
		money -= cost
	else: weapon = "pistol"
	if money >= 650 and armor < 50: armor = 100; money -= 650
	magazine = int(WEAPONS.DATA[weapon]["mag"])
	cooldown = 0
	reload_left = 0
	flash_left = 0
	objective_progress = 0
	decision_timer = 0
	target = null
	collision_layer = 2
	collision_mask = 3
	position = point
	velocity = Vector3.ZERO
	objective = game.bot_objective(self)
	_make_model()


func _physics_process(delta: float) -> void:
	if health <= 0: return
	if global_position.y < -8: take_damage(200,null); return
	cooldown = maxf(0,cooldown-delta)
	flash_left = maxf(0,flash_left-delta)
	if reload_left > 0:
		reload_left -= delta
		if reload_left <= 0: magazine = int(WEAPONS.DATA[weapon]["mag"])
	if game.phase != "active" or not game.building.navigation_ready:
		velocity = Vector3.ZERO
		return
	decision_timer -= delta
	if decision_timer <= 0:
		decision_timer = 0.25 + rng.randf() * 0.12
		_choose_target()
		objective = game.bot_objective(self)
		if is_instance_valid(target) and target.health > 0:
			objective = target.global_position
		agent.target_position = objective
	var direction := Vector3.ZERO
	var sees_target: bool = is_instance_valid(target) and target.health > 0 and flash_left <= 0 and game.has_sight(self,target)
	var interacting: bool = game.bot_interact(self,delta,sees_target)
	if not interacting and not agent.is_navigation_finished():
		var next := agent.get_next_path_position()
		direction = Vector3(next.x-global_position.x,0,next.z-global_position.z).normalized()
	if sees_target:
		var distance := global_position.distance_to(target.global_position)
		if distance < 16:
			direction = Vector3.ZERO
		look_at(Vector3(target.global_position.x,global_position.y,target.global_position.z))
		if not interacting and cooldown <= 0 and reload_left <= 0:
			if magazine <= 0: reload_left = float(WEAPONS.DATA[weapon]["reload"])
			else:
				magazine -= 1
				cooldown = maxf(0.18,float(WEAPONS.DATA[weapon]["delay"])) + rng.randf() * game.bot_delay
				var eye := global_position + Vector3(0,1.55,0)
				var aim := target.global_position + Vector3(0,1.25,0)
				game.fire(self,eye,(aim-eye).normalized(),weapon)
	elif direction.length() > 0:
		rotation.y = lerp_angle(rotation.y,atan2(-direction.x,-direction.z),delta*8)
	velocity.x = direction.x * (2.0 if flash_left > 0 else 3.9)
	velocity.z = direction.z * (2.0 if flash_left > 0 else 3.9)
	if not is_on_floor(): velocity.y -= 18*delta
	else: velocity.y = 0
	move_and_slide()


func _choose_target() -> void:
	target = null
	var nearest := 48.0
	for actor in get_tree().get_nodes_in_group("combatants"):
		if actor == self or actor.team == team or actor.health <= 0: continue
		var distance := global_position.distance_to(actor.global_position)
		if distance < nearest and game.has_sight(self,actor):
			target = actor
			nearest = distance


func take_damage(amount: int, attacker: Node3D) -> void:
	if health <= 0: return
	if is_instance_valid(attacker) and attacker != self and attacker.team == team: return
	var absorbed := mini(armor,int(amount*0.4))
	armor -= absorbed
	health = maxi(0,health-(amount-absorbed))
	if is_instance_valid(attacker) and attacker != self: target = attacker
	if health == 0:
		deaths += 1
		collision_layer = 0
		collision_mask = 0
		model.rotation.z = PI/2
		model.position.y = 0.25
		game.on_death(self,attacker)
