extends Node3D
## Four-stop lift with paired sliding landing doors and physical call panels.
const FLOOR_LEVELS := [-1.8,4.0,8.0,12.0]

func nearest_floor(height: float) -> int:
	var result := 0
	for level in range(1,4):
		if absf(height-FLOOR_LEVELS[level]) < absf(height-FLOOR_LEVELS[result]): result = level
	return result

var current_floor := 0
var target_floor := 0
var moving := false
var cabin: Node3D
var rider: CharacterBody3D
var cabin_gate: StaticBody3D
var cabin_panels: Array[Node3D] = []
var gates: Array[Node3D] = []
var door_panels: Array[Array] = []
var door_open: Array[float] = [0.0,0.0,0.0,0.0]
var displays: Array[Label3D] = []
var call_lamps: Array[MeshInstance3D] = []
var speed := 1.8
var hold_open := 0.0
var waiting_floor := -1
var button_idle: StandardMaterial3D
var button_lit: StandardMaterial3D

func _ready() -> void:
	var steel := _material(Color("9aa4aa"),0.7,0.3)
	var lining := _material(Color("737b80"),0.35,0.48)
	var black := _material(Color("192227"),0.0,0.65)
	var light := _material(Color("fff4da"),0.0,0.5,true)
	button_idle = _material(Color("dde9ed"),0.3,0.4,true)
	button_lit = _material(Color("ffbe49"),0.0,0.4,true)
	# A continuous opaque shaft encloses the cabin between landing doors.
	var shaft_bottom: float = FLOOR_LEVELS[0]-0.35
	var shaft_top: float = FLOOR_LEVELS[3]+3.15
	var shaft_height := shaft_top-shaft_bottom
	var shaft_mid := (shaft_bottom+shaft_top)/2
	for z in [-1.48,1.48]:
		_part(self,Vector3(0,shaft_mid,z),Vector3(2.95,shaft_height,0.18),lining)
	_part(self,Vector3(1.48,shaft_mid,0),Vector3(0.18,shaft_height,3.12),lining)
	for z in [-1.67,1.67]:
		_part(self,Vector3(-1.43,shaft_mid,z),Vector3(0.16,shaft_height,0.38),lining)
	for level in range(4):
		var bottom: float = FLOOR_LEVELS[level]+2.93
		var top: float = FLOOR_LEVELS[level+1] if level<3 else shaft_top
		_part(self,Vector3(-1.43,(bottom+top)/2,0),Vector3(0.16,top-bottom,2.98),lining)
	cabin = Node3D.new()
	cabin.name = "MovingCabin"
	cabin.position.y = FLOOR_LEVELS[0]
	add_child(cabin)
	_part(cabin,Vector3(0,-0.10,0),Vector3(2.5,0.2,2.5),steel)
	_part(cabin,Vector3(1.25,1.4,0),Vector3(0.1,2.8,2.5),lining)
	for z in [-1.25,1.25]:
		_part(cabin,Vector3(0,1.4,z),Vector3(2.5,2.8,0.1),lining)
		_part(cabin,Vector3(0,0.92,z*0.94),Vector3(2.1,0.045,0.045),steel,false)
	_part(cabin,Vector3(0,2.8,0),Vector3(2.5,0.12,2.5),steel)
	_part(cabin,Vector3(0,2.72,0),Vector3(1.8,0.03,1.3),light,false)
	_part(cabin,Vector3(1.18,1.65,0),Vector3(0.025,1.55,1.4),steel,false)
	var mirror := Node3D.new()
	mirror.name = "CabinMirror"
	mirror.position = Vector3(1.15,1.65,0)
	mirror.set_script(preload("res://scripts/lift_mirror.gd"))
	cabin.add_child(mirror)
	_part(cabin,Vector3(-0.8,1.35,1.18),Vector3(0.25,0.65,0.04),black,false)
	for level in range(4):
		_part(cabin,Vector3(-0.8,1.58-level*0.14,1.15),Vector3(0.12,0.08,0.025),button_idle,false)
	_part(cabin,Vector3(-1.23,2.74,0),Vector3(0.16,0.18,2.5),steel,false)
	for z in [-1.24,1.24]:
		_part(cabin,Vector3(-1.23,1.35,z),Vector3(0.16,2.7,0.10),steel,false)
	# The cabin has its own sliding doors; landing doors stay at their floor.
	cabin_gate = StaticBody3D.new()
	cabin_gate.name = "CabinDoor"
	cabin_gate.position = Vector3(-1.23,1.35,0)
	var cabin_shape := CollisionShape3D.new()
	var cabin_box := BoxShape3D.new()
	cabin_box.size = Vector3(0.075,2.7,2.4)
	cabin_shape.shape = cabin_box
	cabin_gate.add_child(cabin_shape)
	cabin.add_child(cabin_gate)
	for side in [-1.0,1.0]:
		var panel := _part(cabin_gate,Vector3(0,0,side*0.6),Vector3(0.055,2.68,1.19),steel,false)
		panel.name = "CabinSlidingLeaf"
		cabin_panels.append(panel)
	_part(cabin,Vector3(-1.27,-0.22,0),Vector3(0.12,0.44,2.5),steel,false)
	var lamp := OmniLight3D.new()
	lamp.position.y = 2.4
	lamp.omni_range = 3
	lamp.light_energy = 0.8
	cabin.add_child(lamp)
	for level in range(4):
		var h: float = FLOOR_LEVELS[level]
		for side in [-1.0,1.0]:
			_part(self,Vector3(-1.32,h+1.4,side*1.32),Vector3(0.22,2.8,0.22),steel)
			_part(self,Vector3(-1.29,h+1.4,side*1.6),Vector3(0.12,2.8,0.34),lining)
		_part(self,Vector3(-1.32,h+2.86,0),Vector3(0.22,0.16,2.85),steel)
		_part(self,Vector3(-1.32,h+0.01,0),Vector3(0.3,0.02,2.4),steel,false)
		var gate := StaticBody3D.new()
		gate.name = "LandingDoor_%d" % level
		gate.position = Vector3(-1.29,h+1.35,0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.10,2.7,2.4)
		shape.shape = box
		gate.add_child(shape)
		add_child(gate)
		gates.append(gate)
		var panels: Array = []
		for side in [-1.0,1.0]:
			var panel := _part(gate,Vector3(0,0,side*0.6),Vector3(0.075,2.68,1.19),steel,false)
			panel.name = "SlidingLeaf"
			_part(panel,Vector3(-0.041,0,-side*0.56),Vector3(0.012,2.66,0.016),black,false)
			panels.append(panel)
		door_panels.append(panels)
		_part(self,Vector3(-1.46,h+1.25,1.86),Vector3(0.06,0.42,0.23),steel,false)
		var button := _part(self,Vector3(-1.505,h+1.23,1.86),Vector3(0.035,0.13,0.13),button_idle,false)
		button.name = "CallButton_%d" % level
		call_lamps.append(button.get_child(0) as MeshInstance3D)
		_part(self,Vector3(-1.46,h+3.05,0),Vector3(0.04,0.22,0.62),black,false)
		var label := Label3D.new()
		label.position = Vector3(-1.49,h+3.05,0)
		label.rotation.y = -PI/2
		label.font_size = 28
		label.pixel_size = 0.005
		label.modulate = Color("95e7bd")
		label.outline_size = 0
		add_child(label)
		displays.append(label)
	_update_gates()

func _material(color: Color,metallic: float,roughness: float,emissive: bool=false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
	return mat

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
	var cabin_open: float = door_open[current_floor]
	cabin_gate.collision_layer = 0 if not moving and cabin_open>=0.98 else 1
	for index in range(2):
		var side := -1.0 if index==0 else 1.0
		cabin_panels[index].position.z = side*(0.6+cabin_open*1.22)
	for level in range(4):
		gates[level].collision_layer = 0 if not moving and level==current_floor and door_open[level]>=0.98 else 1
		for index in range(2):
			var side := -1.0 if index==0 else 1.0
			door_panels[level][index].position.z = side*(0.6+door_open[level]*1.22)
		displays[level].text = "%d %s" % [current_floor,("▲" if target_floor>current_floor else "▼") if moving else ""]
		call_lamps[level].material_override = button_lit if level==waiting_floor else button_idle

func contains_actor(actor: Node3D) -> bool:
	var p := to_local(actor.global_position)-cabin.position
	return absf(p.x)<0.9 and absf(p.z)<1.1 and absf(p.y)<0.3

func _near_landing(actor: Node3D) -> bool:
	var p := to_local(actor.global_position)
	var level := nearest_floor(p.y)
	return p.x>-3.4 and p.x<-0.9 and absf(p.z)<2.1 and absf(p.y-FLOOR_LEVELS[level])<0.35

func _doorway_occupied(actor: Node3D) -> bool:
	var p := to_local(actor.global_position)
	return p.x>-1.95 and p.x<-0.85 and absf(p.z)<1.35 and absf(p.y-FLOOR_LEVELS[current_floor])<0.35

func prompt(actor: Node3D) -> String:
	if contains_actor(actor):
		return "LIFT · %d-qavatga harakatlanmoqda" % target_floor if moving else "LIFT · E — keyingi qavat  /  Q — oldingi qavat"
	if not _near_landing(actor): return ""
	var level := nearest_floor(to_local(actor.global_position).y)
	if moving: return "LIFT · harakatlanmoqda, kuting"
	if level==current_floor: return "LIFT · eshik avtomatik ochiladi"
	return "E — chaqirish tugmasini bosing (%d-qavat)" % level

func request_floor(level: int,actor: CharacterBody3D=null) -> bool:
	if moving or level<0 or level>3 or level==current_floor: return false
	if is_instance_valid(actor) and contains_actor(actor):
		rider = actor
		rider.lift_riding = true
		rider.velocity = Vector3.ZERO
	target_floor = level
	waiting_floor = level
	moving = true
	hold_open = 0
	_update_gates()
	return true

func interact(actor: CharacterBody3D,previous: bool=false) -> void:
	if moving: return
	if contains_actor(actor):
		request_floor((current_floor+(3 if previous else 1))%4,actor)
	elif _near_landing(actor):
		var level := nearest_floor(to_local(actor.global_position).y)
		if level==current_floor: hold_open = 3.0
		else: request_floor(level)

func _physics_process(delta: float) -> void:
	var human := get_tree().get_first_node_in_group("human_player") as CharacterBody3D
	var occupied := is_instance_valid(human) and _doorway_occupied(human)
	if not moving:
		hold_open = maxf(0,hold_open-delta)
		if is_instance_valid(human) and human.health>0:
			if contains_actor(human) or (_near_landing(human) and absf(to_local(human.global_position).y-FLOOR_LEVELS[current_floor])<0.35): hold_open = 3.0
		var wanted := 1.0 if hold_open>0 or occupied else 0.0
		door_open[current_floor] = move_toward(door_open[current_floor],wanted,delta*1.6)
	else:
		if not occupied: door_open[current_floor] = move_toward(door_open[current_floor],0.0,delta*1.6)
		if door_open[current_floor]<=0.001 and not occupied:
			var old_y := cabin.position.y
			cabin.position.y = move_toward(old_y,FLOOR_LEVELS[target_floor],speed*delta)
			if is_instance_valid(rider): rider.global_position.y += cabin.position.y-old_y
			if is_equal_approx(cabin.position.y,FLOOR_LEVELS[target_floor]):
				current_floor = target_floor
				moving = false
				hold_open = 3.0
				waiting_floor = -1
				if is_instance_valid(rider): rider.lift_riding = false
				rider = null
	_update_gates()

func detach_actor(actor: CharacterBody3D) -> void:
	if rider == actor:
		rider.lift_riding = false
		rider = null
