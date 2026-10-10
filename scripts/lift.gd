extends Node3D
## Four stops, physical cabin, landing gates and a carried player during travel.
var current_floor := 0
var target_floor := 0
var moving := false
var cabin: Node3D
var rider: CharacterBody3D
var gates: Array[Node3D] = []
var speed := 1.8

func _ready() -> void:
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("969b96")
	steel.metallic = 0.65
	steel.roughness = 0.33
	var lining := StandardMaterial3D.new()
	lining.albedo_color = Color("555b57")
	var light := StandardMaterial3D.new()
	light.albedo_color = Color("fff4da")
	light.emission_enabled = true
	light.emission = Color("fff4da")
	cabin = Node3D.new()
	cabin.name = "MovingCabin"
	add_child(cabin)
	_part(cabin,Vector3(0,-0.10,0),Vector3(2.5,0.2,2.5),steel)
	_part(cabin,Vector3(1.25,1.4,0),Vector3(0.1,2.8,2.5),lining)
	for z in [-1.25,1.25]: _part(cabin,Vector3(0,1.4,z),Vector3(2.5,2.8,0.1),lining)
	_part(cabin,Vector3(0,2.8,0),Vector3(2.5,0.12,2.5),steel)
	_part(cabin,Vector3(0,2.72,0),Vector3(1.5,0.03,0.5),light,false)
	var lamp := OmniLight3D.new()
	lamp.position.y = 2.4
	lamp.omni_range = 3
	lamp.light_energy = 0.8
	cabin.add_child(lamp)
	for level in range(4):
		var gate := _part(self,Vector3(-1.29,level*4+1.35,0),Vector3(0.1,2.7,2.4),steel)
		gates.append(gate)
		var label := Label3D.new()
		label.position = Vector3(-1.42,level*4+2.95,0)
		label.rotation.y = -PI/2
		label.text = "LIFT  %d" % level
		label.font_size = 32
		label.pixel_size = 0.007
		add_child(label)
	_update_gates()

func _part(parent: Node3D,pos: Vector3,size: Vector3,mat: Material,solid: bool=true) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	body.add_child(mesh)
	if solid:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
	parent.add_child(body)
	return body

func _update_gates() -> void:
	for level in range(4):
		var closed := moving or level!=current_floor
		gates[level].visible = closed
		gates[level].collision_layer = 1 if closed else 0

func contains_actor(actor: Node3D) -> bool:
	var p := to_local(actor.global_position)-cabin.position
	return absf(p.x)<1.1 and absf(p.z)<1.1 and absf(p.y)<0.3

func prompt(actor: Node3D) -> String:
	if moving:
		return "LIFT · %d-qavatga harakatlanmoqda" % target_floor if actor==rider else ""
	if contains_actor(actor): return "LIFT · E — keyingi qavat  /  Q — oldingi qavat"
	var p := to_local(actor.global_position)
	if p.x>-3.4 and p.x<-1.2 and absf(p.z)<1.5:
		return "E — liftni chaqirish"
	return ""

func request_floor(level: int,actor: CharacterBody3D=null) -> bool:
	if moving or level<0 or level>3 or level==current_floor: return false
	if is_instance_valid(actor) and contains_actor(actor):
		rider = actor
		rider.lift_riding = true
		rider.velocity = Vector3.ZERO
	target_floor = level
	moving = true
	_update_gates()
	return true

func interact(actor: CharacterBody3D,previous: bool=false) -> void:
	if moving: return
	if contains_actor(actor):
		request_floor((current_floor+(3 if previous else 1))%4,actor)
	elif not prompt(actor).is_empty():
		request_floor(clampi(roundi((actor.global_position.y-global_position.y)/4),0,3))

func _physics_process(delta: float) -> void:
	if not moving: return
	var old_y := cabin.position.y
	cabin.position.y = move_toward(old_y,target_floor*4.0,speed*delta)
	if is_instance_valid(rider):
		rider.global_position.y += cabin.position.y-old_y
	if is_equal_approx(cabin.position.y,target_floor*4.0):
		current_floor = target_floor
		moving = false
		if is_instance_valid(rider): rider.lift_riding = false
		rider = null
		_update_gates()

func detach_actor(actor: CharacterBody3D) -> void:
	if rider == actor:
		rider.lift_riding = false
		rider = null
