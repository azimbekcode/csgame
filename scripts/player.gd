extends CharacterBody3D

const WEAPONS = preload("res://scripts/weapons.gd")

@export var move_speed := 5.5
@export var jump_velocity := 5.8
@export var mouse_sensitivity := 0.002
var team := 0
var actor_name := "Siz"
var health := 100
var armor := 0
var money := 800
var kills := 0
var deaths := 0
var kit := false
var primary := ""
var weapon := "pistol"
var ammunition: Dictionary = {}
var grenades := {"he": 0, "flash": 0, "smoke": 0}
var cooldown := 0.0
var reload_left := 0.0
var flash_left := 0.0
var recoil := 0.0
var view_camera: Camera3D
var weapon_model: Node3D
var scoped := false
var crouched := false
var bob_time := 0.0
var stair_amount := 0.0
var stair_view_offset := 0.0
var footstep_time := 0.0
var round_spawn := Vector3.ZERO
var lift_riding := false
var game: Node3D
var reflection_body: Node3D


func _ready() -> void:
	game = get_parent()
	view_camera = $Camera3D
	add_to_group("combatants")
	add_to_group("human_player")
	fill_ammunition("pistol")
	show_weapon()
	view_camera.cull_mask = 1|4|8


func fill_ammunition(id: String) -> void:
	ammunition[id] = {"mag": int(WEAPONS.DATA[id]["mag"]), "reserve": int(WEAPONS.DATA[id]["reserve"])}


func show_weapon() -> void:
	if is_instance_valid(weapon_model):
		view_camera.remove_child(weapon_model)
		weapon_model.queue_free()
	weapon_model = WEAPONS.make_model(weapon)
	weapon_model.position = Vector3(0.22, -0.23, -0.35)
	weapon_model.scale = Vector3.ONE * 1.3
	view_camera.add_child(weapon_model)
	for mesh in weapon_model.find_children("*","MeshInstance3D",true,false): mesh.layers = 8
	if is_instance_valid(reflection_body): reflection_body.queue_free()
	reflection_body = Node3D.new()
	reflection_body.name = "MirrorPlayerBody"
	reflection_body.set_script(preload("res://scripts/soldier_model.gd"))
	reflection_body.team = team
	reflection_body.weapon = weapon if weapon in ["pistol","ak","m4","mp5"] else "pistol"
	add_child(reflection_body)
	for mesh in reflection_body.find_children("*","MeshInstance3D",true,false):
		mesh.layers = 2
	weapon_model.visible = health > 0
	scoped = false


func equip(id: String) -> void:
	if id == weapon:
		return
	weapon = id
	reload_left = 0.0
	cooldown = 0.2
	show_weapon()


func _unhandled_input(event: InputEvent) -> void:
	if game.input_locked() or health <= 0:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity := mouse_sensitivity * (0.45 if scoped else 1.0)
		rotate_y(-event.relative.x * sensitivity)
		view_camera.rotation.x = clampf(view_camera.rotation.x - event.relative.y * sensitivity, -1.5, 1.5)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				if not primary.is_empty(): equip(primary)
			KEY_2: equip("pistol")
			KEY_3: equip("knife")
			KEY_4: cycle_grenade()
			KEY_R: start_reload()
			KEY_E: game.building.lift.interact(self)
			KEY_Q: game.building.lift.interact(self,true)
			KEY_F1, KEY_F2, KEY_F3, KEY_F4:
				if game.exploring: game.explore_teleport(event.physical_keycode)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and weapon == "awp":
			scoped = not scoped
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			equip("pistol" if weapon == primary else (primary if not primary.is_empty() else "knife"))


func cycle_grenade() -> void:
	var ids := ["he", "flash", "smoke"]
	var start := ids.find(weapon)
	for offset in range(1, 4):
		var id: String = ids[(start + offset) % 3]
		if grenades[id] > 0:
			equip(id)
			return


func _physics_process(delta: float) -> void:
	if lift_riding:
		velocity = Vector3.ZERO
		return
	cooldown = maxf(0, cooldown - delta)
	flash_left = maxf(0, flash_left - delta)
	if reload_left > 0:
		reload_left -= delta
		if reload_left <= 0:
			finish_reload()
	if position.y < -8:
		if game.exploring: reset_to(Vector3(0,0.1,5),0)
		else: take_damage(200, null)
	if health <= 0:
		return
	recoil = move_toward(recoil, 0.0, delta * 3.0)
	var locked: bool = game.input_locked()
	var input_vector := Vector2.ZERO if locked else Input.get_vector("left", "right", "forward", "back")
	_set_crouch(not locked and Input.is_action_pressed("crouch"))
	var direction := (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	var speed := move_speed
	if not locked and Input.is_action_pressed("walk"): speed = 2.8
	if crouched: speed = 2.2
	if scoped: speed *= 0.65
	if game.phase == "freeze" and not game.exploring: speed = 0
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 35.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 35.0)
	if not is_on_floor(): velocity.y -= 18.0 * delta
	elif not locked and Input.is_action_just_pressed("jump") and not crouched:
		velocity.y = jump_velocity
	var previous_height := global_position.y
	move_and_slide()
	var horizontal_speed := Vector2(velocity.x,velocity.z).length()
	var height_speed := (global_position.y-previous_height)/maxf(delta,0.001)
	reflection_body.animate(delta,horizontal_speed,reload_left>0,height_speed if is_on_floor() else 0.0)
	reflection_body.visible = health>0
	var climbing := is_on_floor() and horizontal_speed>0.4 and absf(height_speed)>0.15
	stair_amount = move_toward(stair_amount,1.0 if climbing else 0.0,delta*8.0)
	bob_time += delta*horizontal_speed*2.0
	# Each tread gives a short rise and footfall rather than a floating camera.
	var tread_phase := TAU*global_position.y/0.20
	stair_view_offset = sin(tread_phase)*0.045*stair_amount
	var walk_bob := sin(bob_time*2.0)*0.012 if is_on_floor() and horizontal_speed>0.4 else 0.0
	view_camera.position.y = lerpf(view_camera.position.y,(1.03 if crouched else 1.65)+walk_bob+stair_view_offset,delta*20.0)
	view_camera.rotation.z = lerpf(view_camera.rotation.z,sin(bob_time)*0.009*stair_amount,delta*10.0)
	view_camera.fov = lerpf(view_camera.fov, 28.0 if scoped else 80.0, delta * 15.0)
	if is_instance_valid(weapon_model):
		weapon_model.position = Vector3(0.22, -0.23 + sin(bob_time) * 0.008 + stair_view_offset*0.45, -0.35 + recoil * 0.055)
		weapon_model.rotation.x = recoil * 0.06
		weapon_model.rotation.z = sin(bob_time * 0.5) * 0.012
		weapon_model.visible = not scoped and game.phase != "menu" and not game.exploring
	footstep_time -= delta
	if footstep_time <= 0 and is_on_floor() and Vector2(velocity.x,velocity.z).length() > 3.0:
		footstep_time = 0.42
		game.play_sound("step", global_position, -25.0)
	if locked or not game.can_fire():
		return
	var automatic: bool = WEAPONS.DATA[weapon]["auto"]
	if Input.is_action_pressed("fire") if automatic else Input.is_action_just_pressed("fire"):
		try_fire()


func _set_crouch(value: bool) -> void:
	if not value and crouched:
		var query := PhysicsShapeQueryParameters3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.3
		shape.height = 1.8
		query.shape = shape
		query.transform = global_transform.translated(Vector3(0,0.9,0))
		query.exclude = [get_rid()]
		# Ignore the floor when checking overhead clearance.
		query.margin = -0.01
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return
	crouched = value
	$CollisionShape3D.shape.height = 1.25 if value else 1.8
	$CollisionShape3D.position.y = 0.625 if value else 0.9


func try_fire() -> bool:
	if cooldown > 0 or reload_left > 0 or health <= 0:
		return false
	if weapon in ["he","flash","smoke"]:
		if grenades[weapon] <= 0: return false
		grenades[weapon] -= 1
		game.throw_grenade(self, weapon, view_camera.global_position, -view_camera.global_basis.z)
		cooldown = 0.8
		equip(primary if not primary.is_empty() else "pistol")
		return true
	if weapon != "knife":
		if ammunition[weapon]["mag"] <= 0:
			start_reload()
			return false
		ammunition[weapon]["mag"] -= 1
	cooldown = float(WEAPONS.DATA[weapon]["delay"])
	game.fire(self, view_camera.global_position, -view_camera.global_basis.z, weapon)
	if weapon != "knife":
		recoil = minf(recoil + 0.65, 3.0)
		view_camera.rotation.x = minf(1.5, view_camera.rotation.x + (0.006 if weapon == "pistol" else 0.014))
	return true


func start_reload() -> void:
	if reload_left > 0 or weapon in ["knife","he","flash","smoke"]:
		return
	if ammunition[weapon]["mag"] >= int(WEAPONS.DATA[weapon]["mag"]) or ammunition[weapon]["reserve"] <= 0:
		return
	reload_left = float(WEAPONS.DATA[weapon]["reload"])
	game.play_sound("reload", global_position, -15.0)


func finish_reload() -> void:
	var needed := int(WEAPONS.DATA[weapon]["mag"]) - int(ammunition[weapon]["mag"])
	var transfer := mini(needed, int(ammunition[weapon]["reserve"]))
	ammunition[weapon]["mag"] += transfer
	ammunition[weapon]["reserve"] -= transfer
	reload_left = 0.0


func take_damage(amount: int, attacker: Node3D) -> void:
	if health <= 0 or game.exploring: return
	if is_instance_valid(attacker) and attacker != self and attacker.team == team: return
	var absorbed := mini(armor, int(amount * 0.4))
	armor -= absorbed
	health = maxi(0, health - (amount - absorbed))
	game.hud.hurt_alpha = 0.45
	if health == 0:
		deaths += 1
		scoped = false
		weapon_model.visible = false
		collision_layer = 0
		collision_mask = 0
		game.on_death(self, attacker)


func reset_to(spawn_position: Vector3, yaw: float) -> void:
	if is_instance_valid(game.building.lift): game.building.lift.detach_actor(self)
	lift_riding = false
	position = spawn_position
	rotation.y = yaw
	velocity = Vector3.ZERO
	view_camera.rotation = Vector3.ZERO
	stair_amount = 0.0
	stair_view_offset = 0.0
	bob_time = 0.0


func respawn(spawn_position: Vector3, yaw: float) -> void:
	var was_dead := health <= 0
	health = 100
	if was_dead:
		primary = ""
		armor = 0
		kit = false
		grenades = {"he":0,"flash":0,"smoke":0}
		ammunition.clear()
	fill_ammunition("pistol")
	if not primary.is_empty(): fill_ammunition(primary)
	weapon = primary if not primary.is_empty() else "pistol"
	reload_left = 0.0
	cooldown = 0.0
	flash_left = 0.0
	collision_layer = 2
	collision_mask = 3
	_set_crouch(false)
	round_spawn = spawn_position
	reset_to(spawn_position,yaw)
	show_weapon()
