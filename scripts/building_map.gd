extends Node3D
## Four-level circular reconstruction from the user's front-elevation photograph.
## Interior dimensions are estimates pending the original reference videos.
const SEGMENTS := 96
const INNER_RADIUS := 6.5
const OUTER_RADIUS := 20.0
const FLOOR_HEIGHT := 4.0
const FLOOR_COUNT := 4
const ROOM_RADIUS := 11.0
const GROUND_FLOOR := -1.8

static func floor_height(level: int) -> float:
	return GROUND_FLOOR if level == 0 else level * FLOOR_HEIGHT
const ROOF_HEIGHT := 16.0
const DOME_RADIUS := 12.5
const DOME_BASE := 17.4
const DOME_RISE := 10.6
const LIFT_CENTER := Vector3(-4.4, 0, 16.2)

var marble: StandardMaterial3D
var wood: StandardMaterial3D
var door_wood: StandardMaterial3D
var cream: StandardMaterial3D
var dark: StandardMaterial3D
var metal: StandardMaterial3D
var glass: StandardMaterial3D
var campus_stone: StandardMaterial3D
var paving: StandardMaterial3D
var glow: StandardMaterial3D
var limestone: StandardMaterial3D
var bronze: StandardMaterial3D
var navigation_ready := false
var force_bake := false
var navigation_region: NavigationRegion3D
var room_entries: Array[Vector3] = []
var stair_surfaces: Array[Node3D] = []
var lift: Node3D
const LADDER_BASE := Vector3(21.0,-0.9,0)
const LADDER_TOP := Vector3(19.0,16.05,0)
var material_cache: Dictionary = {}

func _ready() -> void:
	_make_materials()
	campus_stone = _textured_material("campus_tiles",Color("a9aa9e"),0.88)
	limestone = _textured_material("stone", Color("e2d8bd"), 0.87)
	bronze = _material(Color("55402c"), 0.42)
	_make_environment()
	_make_floors()
	_make_facade()
	_make_rooms()
	_make_stairs()
	_make_entrances()
	_make_gallery_air_conditioners()
	_make_dome()
	_make_lift()
	_make_roof_ladder()
	_make_campus()
	_make_left_facade_lane()
	_make_rectangular_boundary()
	_make_rear_reference_house()
	_make_campus_link()
	_make_lobby_fixtures()
	_batch_static_visuals()
	call_deferred("_setup_navigation")

func _make_floors() -> void:
	_cylinder(Vector3(0,GROUND_FLOOR-0.15,0), ROOM_RADIUS, 0.3, marble,SEGMENTS)
	for level in range(FLOOR_COUNT):
		var h := floor_height(level)
		for segment in range(SEGMENTS):
			var a := TAU * segment / SEGMENTS
			var b := TAU * (segment+1) / SEGMENTS
			_wedge(0.0 if level == 0 else INNER_RADIUS, ROOM_RADIUS, a,b,h,0.28,marble,true)
			_wedge(ROOM_RADIUS,OUTER_RADIUS,a,b,h,0.28,marble,true)
			if level > 0:
				_make_balcony_rail(a,b,h)
				_wedge(INNER_RADIUS,ROOM_RADIUS,a,b,h-0.29,0.025,cream,false)
			if level == FLOOR_COUNT-1: _wedge(INNER_RADIUS,OUTER_RADIUS,a,b,ROOF_HEIGHT,0.23,cream,true)
		for light_index in range(16):
			var lamp := OmniLight3D.new()
			lamp.position = _polar(9.0,TAU*light_index/16.0,h+3.4)
			lamp.light_color = Color("fff0d8")
			lamp.light_energy = 0.22
			lamp.omni_range = 8
			add_child(lamp)
			_box(lamp.position+Vector3(0,0.28,0),Vector3(0.16,0.035,0.16),glow,0,false)
	_cylinder(Vector3(0,GROUND_FLOOR+0.013,0),3.3,0.02,_material(Color("555b50")))
	_cylinder(Vector3(0,GROUND_FLOOR+0.028,0),3.05,0.02,_material(Color("286251")))
	for i in range(24):
		var a := TAU*i/24
		_beam(_polar(1.0,a,GROUND_FLOOR+0.05),_polar(2.5,a+0.18,GROUND_FLOOR+0.05),0.03,metal)
	var emblem := _label("SAMARQAND DAVLAT\nUNIVERSITETI",Vector3(0,GROUND_FLOOR+0.08,0),0,0.012)
	emblem.rotation.x = -PI/2
	for i in range(16):
		var a := TAU*i/16.0
		_beam(_polar(0.8,a,GROUND_FLOOR+0.055),_polar(2.8,a,GROUND_FLOOR+0.055),0.025,bronze)

func _make_balcony_rail(a: float,b: float,h: float) -> void:
	var mid := (a+b)/2
	var length := 2*INNER_RADIUS*sin((b-a)/2)
	_box(_polar(INNER_RADIUS,mid,h+0.55),Vector3(length,0.9,0.06),glass,-mid-PI/2)
	_beam(_polar(INNER_RADIUS,a,h+1.08),_polar(INNER_RADIUS,b,h+1.08),0.035,metal)
	if int(round(a/TAU*SEGMENTS)) % 3 == 0:
		_beam(_polar(INNER_RADIUS,a,h),_polar(INNER_RADIUS,a,h+1.1),0.028,metal)
	_box(_polar(INNER_RADIUS,mid,h-0.14),Vector3(length,0.23,0.1),bronze,-mid-PI/2,false)

func _make_facade() -> void:
	var plinth := _textured_material("stone",Color("747a7b"),0.92)
	# Twenty-four broad bays; the tall arched glazing occupies the entire top storey.
	for bay in range(24):
		var a := TAU*bay/24.0
		var front := bay == 18
		var rear := bay == 6
		var yaw := -a-PI/2
		var width := 2*OUTER_RADIUS*sin(PI/24)
		for level in range(3):
			var base := float(level)*4
			var height := 4.0 if level < 2 else 8.0
			var opening := (front and level in [0,1]) or (rear and level in [0,1])
			var win_width := 3.0 if bay%3==0 else 1.9
			var win_height := 2.5 if level < 2 else 6.4
			var mat: Material = plinth if level == 0 else limestone
			if level==0 and not front and not rear:
				var depth := 1.8
				_local_box(a,Vector3(0,-depth/2,20),Vector3(width+0.04,depth,0.45),mat)
			var sill := 0.55
			if front and level == 2:
				win_width = 2.9
				win_height = 2.5
				sill = 3.7
			if rear and level == 2:
				win_width = 2.0
				win_height = 1.8
				sill = 4.5
			if opening:
				_local_box(a,Vector3(-2.05,base+height/2,20),Vector3(1.1,height,0.45),mat)
				_local_box(a,Vector3(2.05,base+height/2,20),Vector3(1.1,height,0.45),mat)
				_local_box(a,Vector3(0,base+3.7,20),Vector3(3,0.6,0.45),mat)
			else:
				var side_width := (width-win_width)/2
				for side in [-1.0,1.0]:
					_local_box(a,Vector3(side*(win_width+side_width)/2,base+height/2,20),Vector3(side_width+0.06,height,0.45),mat)
				_local_box(a,Vector3(0,base+sill/2,20),Vector3(win_width,sill,0.45),mat)
				_local_box(a,Vector3(0,base+(sill+win_height+height)/2,20),Vector3(win_width,height-sill-win_height,0.45),mat)
				_window(_polar(20.02,a,base+sill+win_height/2),yaw,win_width,win_height,level==2 and not rear)
			# Fine horizontal rustication joints catch the light without noisy textures.
			for row in range(int(height/0.45)):
				var yy := base+0.2+row*0.45
				for side in [-1.0,1.0]:
					_local_box(a,Vector3(side*(width+win_width)/4,yy,20.24),Vector3((width-win_width)/2,0.012,0.008),limestone,false)
		# Classical pilasters, bases and capitals separate the bays.
		var edge_a := a-PI/24
		for h in [5.95,11.95]:
			var column_height := 3.5 if h<8 else 7.3
			_box(_polar(20.30,edge_a,h),Vector3(0.33,column_height,0.28),cream,-edge_a-PI/2,false)
			for sign_y in [-1.0,1.0]:
				_box(_polar(20.4,edge_a,h+sign_y*(column_height/2-0.06)),Vector3(0.55,0.18,0.4),cream,-edge_a-PI/2,false)
	for h in [-0.75,3.85,4.03,7.9,8.06,15.65,15.85,16.1]:
		_band(h,20.34,0.16 if h<14 else 0.21,cream)
	for i in range(192):
		var a := TAU*i/192
		_box(_polar(20.42,a,15.55),Vector3(0.17,0.22,0.22),cream,-a,false)
	# Tall centered front portal, inset upper window, cornice and bronze doors.
	for side in [-1.0,1.0]:
		_box(Vector3(side*2.8,10.1,-20.3),Vector3(0.8,12.2,0.95),limestone)
		_box(Vector3(side*2.62,10.1,-20.84),Vector3(0.19,11.8,0.15),cream,0,false)
		_box(Vector3(side*1.78,6.05,-20.55),Vector3(0.33,4.1,0.48),cream)
		_box(Vector3(side*2.8,4.15,-20.35),Vector3(1.04,0.4,1.1),cream)
	_box(Vector3(0,15.9,-20.45),Vector3(6.5,0.52,1.15),cream)
	_box(Vector3(0,9.25,-20.7),Vector3(6.3,0.38,1.15),cream)
	_box(Vector3(0,8.82,-20.55),Vector3(6.0,0.23,0.6),cream)
	_box(Vector3(0,7.65,-20.35),Vector3(3.1,0.58,0.6),bronze)
	_label("SHAROF RASHIDOV NOMIDAGI\nSAMARQAND DAVLAT UNIVERSITETI",Vector3(0,8.47,-21.05),PI,0.0027)
	# Open double doors leave a real walkable 2.7 m opening.
	for side in [-1.0,1.0]:
		_box(Vector3(side*1.6,5.5,-21.2),Vector3(0.08,3,1.35),bronze)
		_box(Vector3(side*1.55,5.75,-21.2),Vector3(0.035,2.1,1.1),glass,0,false)

func _local_box(a: float,point: Vector3,size: Vector3,mat: Material,solid: bool=true) -> void:
	var tangent := Vector3(-sin(a),0,cos(a))
	_box(_polar(point.z,a,point.y)+tangent*point.x,size,mat,-a-PI/2,solid)

func _band(h: float,radius: float,height: float,mat: Material) -> void:
	for i in range(SEGMENTS):
		var a := TAU*(i+0.5)/SEGMENTS
		var point := _polar(radius,a,h)
		# The low facade trim must stop at the sunken front/rear door jambs.
		if h<0 and absf(point.x)<1.95 and absf(point.z)>19: continue
		_box(_polar(radius,a,h),Vector3(2*radius*sin(PI/SEGMENTS)+0.02,height,0.24),mat,-a-PI/2,false)

func _window(origin: Vector3,yaw: float,width: float,height: float,arched: bool=false) -> void:
	var assembly := Node3D.new()
	assembly.position = origin
	assembly.rotation.y = yaw
	add_child(assembly)
	var pane_mat := _material(Color(0.73,0.85,0.91,0.16),0.10)
	pane_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pane_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane_mat.metallic = 0.35
	var pane := _box(Vector3.ZERO,Vector3(width,height,0.035),pane_mat,0,true)
	pane.reparent(assembly,false)
	for x in [-width/2,0.0,width/2]:
		var frame := _box(Vector3(x,0,-0.055),Vector3(0.07,height+0.12,0.10),bronze,0,false)
		frame.reparent(assembly,false)
	for y in [-height/2,height/2,-height*0.16]:
		var frame := _box(Vector3(0,y,-0.055),Vector3(width+0.1,0.07,0.10),bronze,0,false)
		frame.reparent(assembly,false)
	# Arch infill masks the rectangular glass corners, producing a true arched outline.
	if arched:
		var radius := width/2
		var spring := height/2-radius
		for i in range(24):
			var x0 := -radius+width*i/24
			var x1 := -radius+width*(i+1)/24
			var arc_y := spring+sqrt(maxf(0,radius*radius-pow((x0+x1)/2,2)))
			var infill := height/2-arc_y
			if infill>0.005:
				var piece := _box(Vector3((x0+x1)/2,arc_y+infill/2,-0.1),Vector3(width/24+0.01,infill,0.2),limestone,0,false)
				piece.reparent(assembly,false)
		for i in range(24):
			var a := PI*i/24
			var b := PI*(i+1)/24
			var first := get_child_count()
			_beam(Vector3(cos(a)*radius,spring+sin(a)*radius,-0.18),Vector3(cos(b)*radius,spring+sin(b)*radius,-0.18),0.075,cream)
			get_child(first).reparent(assembly,false)
	# Pale reflected vertical sky streaks give depth without emissive flat-blue panes.
	for side in [-0.28,0.24]:
		var reflection := _box(Vector3(width*side,0,-0.075),Vector3(0.035,height*0.84,0.012),_material(Color("536269"),0.2),0,false)
		reflection.reparent(assembly,false)

func _make_rooms() -> void:
	var door_angles := [45.0,135.0,180.0,225.0,315.0]
	for level in range(FLOOR_COUNT):
		var h := floor_height(level)
		var height := floor_height(level+1)-h-0.28
		for i in range(SEGMENTS):
			var a := TAU*(i+0.5)/SEGMENTS
			var degrees := rad_to_deg(a)
			var doorway := absf(degrees-90)<10 or absf(degrees-270)<10
			# Open the lift alcove into the rear lobby at every landing.
			if degrees>100 and degrees<112.5: doorway = true
			for d in door_angles+[247.5,292.5]:
				doorway = doorway or absf(degrees-d)<6
			var width := 2*ROOM_RADIUS*sin(PI/SEGMENTS)+0.018
			if doorway:
				_box(_polar(ROOM_RADIUS,a,h+(height+2.8)/2),Vector3(width,height-2.8,0.17),wood,-a-PI/2)
			else:
				_box(_polar(ROOM_RADIUS,a,h+height/2),Vector3(width,height,0.17),wood,-a-PI/2)
				if i%3==0:
					_box(_polar(ROOM_RADIUS-0.10,a,h+1.86),Vector3(0.025,3.7,0.025),dark,-a-PI/2,false)
				for band in [0.10,1.35,2.65,3.68]:
					_box(_polar(ROOM_RADIUS-0.10,a,h+band),Vector3(width,0.022,0.025),dark,-a-PI/2,false)
				_box(_polar(ROOM_RADIUS-0.1,a,h+1.05),Vector3(width,0.04,0.035),bronze,-a-PI/2,false)
		for d in [22.5,67.5,112.5,157.5,202.5,337.5]:
			var a := deg_to_rad(d)
			_box(_polar(15.4,a,h+height/2),Vector3(8.7,height,0.17),wood,-a)
		for index in range(door_angles.size()):
			var a := deg_to_rad(door_angles[index])
			room_entries.append(_polar(12.6,a,h+0.05))
			_label("%d%02d  /  %s" % [level,index+1,"AUDITORIYA" if index==2 else "XONA"],_polar(10.84,a,h+3.0),-a+PI/2,0.004)
			# Frame sits in the actual wall opening; the leaf pivots at its jamb.
			var door := Node3D.new()
			door.position = _polar(ROOM_RADIUS,a,h)
			door.rotation.y = PI/2-a
			door.name = "BrownRoomDoor_%d_%d" % [level,index]
			add_child(door)
			var first := get_child_count()
			for side in [-1.0,1.0]:
				_box(Vector3(side*1.24,1.4,0),Vector3(0.55,2.8,0.20),wood)
				_box(Vector3(side*0.94,1.4,-0.04),Vector3(0.13,2.8,0.24),door_wood)
			_box(Vector3(0,2.75,-0.04),Vector3(2.0,0.15,0.24),door_wood)
			for node in get_children().slice(first): node.reparent(door,false)
			var hinge := Node3D.new()
			hinge.name = "HingedLeaf"
			hinge.position = Vector3(-0.86,0,0)
			hinge.rotation.y = -PI/2
			door.add_child(hinge)
			first = get_child_count()
			_box(Vector3(0.82,1.34,0),Vector3(1.64,2.68,0.065),door_wood)
			for y in [0.68,1.95]:
				for z in [-0.041,0.041]:
					_box(Vector3(0.82,y,z),Vector3(1.35,1.03,0.022),door_wood,0,false)
			for z in [-0.075,0.075]:
				_box(Vector3(1.47,1.12,z),Vector3(0.045,0.20,0.025),metal,0,false)
				_box(Vector3(1.37,1.15,z),Vector3(0.23,0.035,0.05),metal,0,false)
			for y in [0.24,1.34,2.44]:
				_cylinder(Vector3(0.015,y,0),0.025,0.13,metal)
			for node in get_children().slice(first): node.reparent(hinge,false)
			_make_lecture_room(_polar(13.2,a,h),PI/2-a,height)
			var lamp := OmniLight3D.new()
			lamp.position = _polar(15,a,h+3.2)
			lamp.omni_range = 7
			lamp.light_energy = 0.5
			lamp.light_color = Color("fff1d9")
			add_child(lamp)
		# Both axial entrances keep uninterrupted wood-lined corridors.
		for x in [-2.2,2.2]:
			for z in [-15.25,15.25]:
				_box(Vector3(x,h+(floor_height(level+1)-h)/2,z),Vector3(0.16,floor_height(level+1)-h,9.2),wood)


func _make_lecture_room(origin: Vector3,yaw: float,ceiling_height: float) -> void:
	var room := Node3D.new()
	room.name = "TieredLectureRoom_%d" % get_child_count()
	room.position = origin
	room.rotation.y = yaw
	add_child(room)
	var first := get_child_count()
	var seats := _material(Color("30373b"),0.65)
	var floor_finish := _textured_material("wood",Color("baaa87"),0.8) if not material_cache.has("lecture_floor") else material_cache["lecture_floor"] as StandardMaterial3D
	material_cache["lecture_floor"] = floor_finish
	# Two desk banks leave a clear stepped aisle through the centre.
	for row in range(4):
		var z := 0.65+row*1.3
		var h := (row+1)*0.18
		for side in [-1.0,1.0]:
			var x: float = side*1.95
			_box(Vector3(x,h/2,z),Vector3(2.55,h,1.3),floor_finish)
			_box(Vector3(x,h+0.77,z-0.22),Vector3(2.45,0.08,0.62),wood)
			_box(Vector3(x,h+0.40,z-0.48),Vector3(2.45,0.65,0.06),seats,0,false)
			for seat in range(3):
				var xx: float = x+(seat-1)*0.76
				_box(Vector3(xx,h+0.46,z+0.35),Vector3(0.57,0.07,0.48),seats,0,false)
				_box(Vector3(xx,h+0.79,z+0.58),Vector3(0.57,0.56,0.06),seats,0,false)
				for leg in [-0.22,0.22]:
					_box(Vector3(xx+leg,h+0.22,z+0.35),Vector3(0.035,0.44,0.36),metal,0,false)
			for edge in [-1.13,1.13]:
				_box(Vector3(x+edge,h+0.37,z-0.22),Vector3(0.045,0.74,0.5),metal,0,false)
		_box(Vector3(0,h-0.08,z),Vector3(1.3,0.16,1.3),floor_finish,0,false)
		_box(Vector3(0,h-0.025,z-0.65),Vector3(1.3,0.04,0.07),dark,0,false)
	_ramp(0,1.3,0,-0.65,5.2,0.72)
	# Front presentation area and a white ceiling with recessed round lights.
	_box(Vector3(3.35,1.3,-0.70),Vector3(0.06,1.0,1.8),dark,0,false)
	_box(Vector3(0,ceiling_height+0.01,2.2),Vector3(6.5,0.08,6.3),cream,0,false)
	for x in [-2.1,2.1]:
		for z in [0.0,2.3,4.5]:
			_cylinder(Vector3(x,ceiling_height-0.06,z),0.16,0.025,glow)
	_box(Vector3(0,ceiling_height-0.1,2.2),Vector3(0.94,0.12,0.94),cream,0,false)
	_box(Vector3(0,ceiling_height-0.17,2.2),Vector3(0.64,0.025,0.64),seats,0,false)
	for stripe in range(8):
		_box(Vector3(0,ceiling_height-0.19,1.95+stripe*0.07),Vector3(0.59,0.015,0.025),metal,0,false)
	for x in [-5.05,0.0,5.05]:
		var window_z := 6.72 if x==0 else 6.10
		var window_width := 2.9 if x==0 else 1.9
		_box(Vector3(x,2.86,window_z),Vector3(window_width,0.12,0.12),seats,0,false)
		for slat in range(4):
			_box(Vector3(x,2.72-slat*0.16,window_z),Vector3(window_width-0.05,0.055,0.035),seats,0,false)
	for node in get_children().slice(first): node.reparent(room,false)

func _desk(origin: Vector3,yaw: float) -> void:
	var assembly := Node3D.new()
	assembly.position = origin
	assembly.rotation.y = yaw
	add_child(assembly)
	var first := get_child_count()
	_box(Vector3(0,0.76,0),Vector3(1.3,0.07,0.65),wood)
	for x in [-0.5,0.5]:
		for z in [-0.22,0.22]:
			_box(Vector3(x,0.37,z),Vector3(0.045,0.74,0.045),metal,0,false)
	_box(Vector3(0,0.46,0.6),Vector3(0.42,0.065,0.4),wood)
	_box(Vector3(0,0.74,0.78),Vector3(0.42,0.5,0.05),wood)
	for node in get_children().slice(first): node.reparent(assembly,false)

func stair_point(side: float, x: float, radius: float, height: float) -> Vector3:
	var a := deg_to_rad(247.5 if side<0 else 292.5)
	return _polar(radius,a,height)+Vector3(sin(a),0,-cos(a))*x

func _make_stairs() -> void:
	# Separate atrium portals at the two marked bays, each with a short corridor.
	for side in [-1.0,1.0]:
		var assembly := Node3D.new()
		assembly.name = "MarkedStairBay_%d" % int(side)
		assembly.rotation.y = PI/2-deg_to_rad(247.5 if side<0 else 292.5)
		add_child(assembly)
		var first := get_child_count()
		for level in range(FLOOR_COUNT):
			var h := floor_height(level)
			var wall_height := floor_height(level+1)-h-0.28
			for edge in [-1.0,1.0]:
				_box(Vector3(edge*1.27,h+1.4,11),Vector3(0.7,2.8,0.2),wood)
				_box(Vector3(edge*0.94,h+1.4,11),Vector3(0.1,2.8,0.24),door_wood)
				_box(Vector3(edge*0.96,h+wall_height/2,11.4),Vector3(0.16,wall_height,1.2),wood)
				_box(Vector3(edge*2.05,h+wall_height/2,15.5),Vector3(0.18,wall_height,7.2),wood)
				_box(Vector3(edge*1.5,h+wall_height/2,11.9),Vector3(1.1,wall_height,0.18),wood)
			_box(Vector3(0,h+2.85,11),Vector3(2.0,0.14,0.24),door_wood)
			_box(Vector3(0,h+3.74,11.4),Vector3(2.08,0.12,1.2),cream,0,false)
			_box(Vector3(0,h+wall_height/2,19.1),Vector3(4.28,wall_height,0.18),wood)
			_box(Vector3(0,h-0.14,12.9),Vector3(3.9,0.28,1.2),marble)
			_label("ZINA / 0–3",Vector3(0,h+3.15,10.85),PI,0.0035)
			for edge in [-1.85,1.85]:
				_stair_railing(Vector3(edge,h,12.3),Vector3(edge,h,13.8))
			if level>0:
				_stair_railing(Vector3(-0.25,h,13.5),Vector3(0.25,h,13.5))
				_box(Vector3(0,h+0.55,13.5),Vector3(0.5,1.1,0.08),metal).visible = false
			if level==FLOOR_COUNT-1:
				_stair_railing(Vector3(-1.85,h,13.5),Vector3(-0.25,h,13.5))
				_box(Vector3(-1.05,h+0.55,13.5),Vector3(1.6,1.1,0.08),metal).visible = false
				continue
			var half_rise := (floor_height(level+1)-h)/2
			for edge in [-1.85,1.85]:
				_stair_railing(Vector3(edge,h+half_rise,17.4),Vector3(edge,h+half_rise,18.9))
			_stair_railing(Vector3(0.25,floor_height(level+1),13.5),Vector3(0.25,floor_height(level+1),13.8))
			_box(Vector3(0,h+half_rise-0.14,18.15),Vector3(3.7,0.28,1.5),marble,0,false)
			_box(Vector3(0,h+half_rise-0.14,18.15),Vector3(0.5,0.28,1.5),marble)
			_stair_railing(Vector3(-1.85,h+half_rise,18.9),Vector3(1.85,h+half_rise,18.9))
			_box(Vector3(0,h+half_rise+0.55,18.9),Vector3(3.7,1.1,0.08),metal).visible = false
			_stair_flight(-1.05,h,13.8,17.4,half_rise,1.6,1.5,0.8)
			_stair_flight(1.05,h+half_rise,17.4,13.8,half_rise,1.6,1.0,1.5)
			for edge in [-1.85,-0.25]:
				_stair_railing(Vector3(edge,h,13.8),Vector3(edge,h+half_rise,17.4))
			for edge in [0.25,1.85]:
				_stair_railing(Vector3(edge,h+half_rise,17.4),Vector3(edge,floor_height(level+1),13.8))
		for node in get_children().slice(first): node.reparent(assembly,false)

func _stair_flight(x: float,base: float,start_z: float,end_z: float,rise: float,width: float=2.2,landing_extension: float=0.0,start_extension: float=0.0,finish: Material=null,foundation: float=NAN,facade_side: float=0.0) -> void:
	var tread_finish: Material = marble if finish==null else finish
	var steps := int(ceil(absf(rise)/0.16))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# One watertight stepped skin replaces overlapping tread boxes and slab sides.
	for step in range(steps):
		var a := lerpf(start_z,end_z,float(step)/steps)
		var b := lerpf(start_z,end_z,float(step+1)/steps)
		var lo := minf(a,b)
		var hi := maxf(a,b)
		var top := base+rise*(step+1)/steps
		var low_bottom := base+rise*(lo-start_z)/(end_z-start_z)-0.28 if is_nan(foundation) else foundation
		var high_bottom := base+rise*(hi-start_z)/(end_z-start_z)-0.28 if is_nan(foundation) else foundation
		var left_lo := x-width/2
		var left_hi := x-width/2
		var right_lo := x+width/2
		var right_hi := x+width/2
		if facade_side>0:
			left_lo = -21.4+sqrt(OUTER_RADIUS*OUTER_RADIUS-pow(2.1+lo,2))-0.02
			left_hi = -21.4+sqrt(OUTER_RADIUS*OUTER_RADIUS-pow(2.1+hi,2))-0.02
		elif facade_side<0:
			right_lo = 21.4-sqrt(OUTER_RADIUS*OUTER_RADIUS-pow(2.1+lo,2))+0.02
			right_hi = 21.4-sqrt(OUTER_RADIUS*OUTER_RADIUS-pow(2.1+hi,2))+0.02
		var tl := Vector3(left_lo,top,lo)
		var tr := Vector3(right_lo,top,lo)
		var bl := Vector3(left_hi,top,hi)
		var br := Vector3(right_hi,top,hi)
		var tlb := Vector3(left_lo,low_bottom,lo)
		var trb := Vector3(right_lo,low_bottom,lo)
		var blb := Vector3(left_hi,high_bottom,hi)
		var brb := Vector3(right_hi,high_bottom,hi)
		_quad(surface,tl,bl,br,tr)
		_quad(surface,tr,br,brb,trb)
		_quad(surface,bl,tl,tlb,blb)
		_quad(surface,tlb,trb,brb,blb)
		# The start/end faces and risers meet edge-to-edge, with no coincident faces.
		if step==0:
			if a==lo: _quad(surface,tl,tr,trb,tlb)
			else: _quad(surface,br,bl,blb,brb)
		if step==steps-1:
			if b==hi: _quad(surface,br,bl,blb,brb)
			else: _quad(surface,tl,tr,trb,tlb)
		else:
			var next_top := base+rise*(step+2)/steps
			var edge_l := bl if b==hi else tl
			var edge_r := br if b==hi else tr
			var next_l := Vector3(edge_l.x,next_top,b)
			var next_r := Vector3(edge_r.x,next_top,b)
			if (rise>0)==(b==hi): _quad(surface,edge_r,edge_l,next_l,next_r)
			else: _quad(surface,edge_l,edge_r,next_r,next_l)
		var front_z := a+signf(end_z-start_z)*0.03
		_box(Vector3(x,top+0.007,front_z),Vector3(width-0.08,0.014,0.055),dark,0,false).name = "TreadNosing"
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = tread_finish
	add_child(mesh)
	var ramp_x := x if facade_side==0 else -facade_side*0.4
	var ramp_width := width if facade_side==0 else width+0.8
	_ramp(ramp_x,ramp_width,base,start_z,end_z,rise,landing_extension,start_extension,foundation)
	var support := get_child(get_child_count()-1) as Node3D
	support.set_meta("treads",{"x":ramp_x,"width":ramp_width,"base":base,"start":start_z,"end":end_z,"rise":rise,"steps":steps})
	stair_surfaces.append(support)

func stair_surface_at(point: Vector3) -> Dictionary:
	for support in stair_surfaces:
		var p := support.to_local(point)
		var tread: Dictionary = support.get_meta("treads")
		var t: float = (p.z-tread.start)/(tread.end-tread.start)
		if absf(p.x-tread.x)>tread.width/2 or t<0 or t>1: continue
		var slope_height: float = tread.base+t*tread.rise
		if absf(p.y-slope_height)>0.24: continue
		var step_index := clampi(int(ceil(t*tread.steps)),1,tread.steps)
		return {"offset":tread.base+step_index*tread.rise/tread.steps-slope_height,"depth":absf(tread.end-tread.start)/tread.steps}
	return {}

func _stair_railing(a: Vector3,b: Vector3) -> void:
	var railing := Node3D.new()
	railing.name = "StairRailing_%d" % get_child_count()
	add_child(railing)
	var first := get_child_count()
	_beam(a+Vector3.UP,b+Vector3.UP,0.035,metal)
	_beam(a+Vector3.UP*0.12,b+Vector3.UP*0.12,0.025,metal)
	var count := maxi(1,int(ceil(a.distance_to(b)/0.38)))
	for i in range(count+1):
		var foot := a.lerp(b,float(i)/count)
		_beam(foot+Vector3.UP*0.08,foot+Vector3.UP,0.018,dark)
	for node in get_children().slice(first): node.reparent(railing,false)

func _glass_guard(a: Vector3,b: Vector3) -> void:
	var root := Node3D.new()
	root.name = "FrontGlassGuard_%d" % get_child_count()
	add_child(root)
	var first := get_child_count()
	var count := maxi(1,int(ceil(a.distance_to(b)/1.4)))
	var normal := (b-a).normalized().cross(Vector3.UP).normalized()*0.03
	for segment in range(count):
		var lo := a.lerp(b,float(segment)/count)
		var hi := a.lerp(b,float(segment+1)/count)
		var points := PackedVector3Array([lo+Vector3.UP*0.12-normal,hi+Vector3.UP*0.12-normal,hi+Vector3.UP*1.0-normal,lo+Vector3.UP*1.0-normal])
		for i in range(4): points.append(points[i]+normal*2)
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_quad(surface,points[0],points[3],points[2],points[1])
		_quad(surface,points[4],points[5],points[6],points[7])
		for i in range(4): _quad(surface,points[i],points[(i+1)%4],points[(i+1)%4+4],points[i+4])
		var instance := MeshInstance3D.new()
		instance.mesh = surface.commit()
		instance.material_override = glass
		add_child(instance)
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
	for i in range(count+1):
		var foot := a.lerp(b,float(i)/count)
		_box(foot+Vector3.UP*0.51,Vector3(0.07,1.02,0.07),metal,0,false)
		_box(foot+Vector3.UP*0.025,Vector3(0.16,0.05,0.16),metal,0,false)
		_box(foot+Vector3.UP*1.055,Vector3(0.12,0.045,0.12),metal,0,false)
	_beam(a+Vector3.UP*1.06,b+Vector3.UP*1.06,0.035,metal)
	for node in get_children().slice(first): node.reparent(root,false)

func _ramp(x: float,width: float,base: float,start_z: float,end_z: float,rise: float,landing_extension: float=0.0,start_extension: float=0.0,foundation: float=NAN) -> void:
	var points := PackedVector3Array()
	for side in [-1.0,1.0]:
		points.append(Vector3(x+side*width/2,base-0.15 if is_nan(foundation) else foundation,start_z))
		points.append(Vector3(x+side*width/2,base,start_z))
		points.append(Vector3(x+side*width/2,base+rise-0.15 if is_nan(foundation) else foundation,end_z))
		points.append(Vector3(x+side*width/2,base+rise,end_z))
	if start_extension>0:
		var landing_start := start_z-signf(end_z-start_z)*start_extension
		_box(Vector3(x,base-0.075,(start_z+landing_start)/2),Vector3(width,0.15,start_extension),marble).visible = false
	if landing_extension>0:
		var landing_end := end_z+signf(end_z-start_z)*landing_extension
		for side in [-1.0,1.0]:
			points.append(Vector3(x+side*width/2,base+rise-0.15,landing_end))
			points.append(Vector3(x+side*width/2,base+rise,landing_end))
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var body := StaticBody3D.new()
	body.name = "WalkableRamp"
	body.add_child(collision)
	add_child(body)

func _flat_polygon_prism(polygon: PackedVector2Array,top: float,bottom: float,finish: Material) -> Node3D:
	var indices := Geometry2D.triangulate_polygon(polygon)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	for i in range(0,indices.size(),3):
		var points := PackedVector3Array()
		for corner in range(3):
			var point := polygon[indices[i+corner]]
			points.append(Vector3(point.x,top,point.y))
		for corner in range(3): points.append(Vector3(points[corner].x,bottom,points[corner].z))
		_quad(surface,points[0],points[2],points[1],points[0])
		_quad(surface,points[3],points[4],points[5],points[3])
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
	for i in range(polygon.size()):
		var a := polygon[i]
		var b := polygon[(i+1)%polygon.size()]
		_quad(surface,Vector3(a.x,top,a.y),Vector3(b.x,top,b.y),Vector3(b.x,bottom,b.y),Vector3(a.x,bottom,a.y))
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = finish
	body.add_child(mesh)
	add_child(body)
	return body

func _make_front_forecourt_foundation() -> void:
	var assembly := Node3D.new()
	assembly.name = "FrontSealedFoundation"
	add_child(assembly)
	var first := get_child_count()
	var circle := PackedVector2Array()
	for i in range(SEGMENTS): circle.append(Vector2(cos(TAU*i/SEGMENTS),sin(TAU*i/SEGMENTS))*OUTER_RADIUS)
	# Continuous buried footing also seals precision seams between adjacent colliders.
	var footing := PackedVector2Array([Vector2(-7.72,-33),Vector2(7.55,-33),Vector2(7.55,-19),Vector2(-7.72,-19)])
	for piece in Geometry2D.clip_polygons(footing,circle):
		_flat_polygon_prism(piece,GROUND_FLOOR-0.04,-2.20,marble).name = "ContinuousBuriedFooting"
	# Disjoint floor panels meet the circular ground floor and exclude all steps.
	# This removes both holes and the coplanar floor/last-tread flicker.
	var xs := [-7.72,-7.24,-4.6,-4.4,-2.1,0.0,2.1,4.4,4.6,7.16,7.55]
	var zs := [-33.0,-32.0,-28.0,-24.4,-22.6,-19.0]
	for ix in range(xs.size()-1):
		for iz in range(zs.size()-1):
			var x: float = (xs[ix]+xs[ix+1])/2
			var z: float = (zs[iz]+zs[iz+1])/2
			if x>4.6 and x<7.16 and z>-32 and z<-28: continue
			if x< -4.6 and x> -7.24 and z< -24.4: continue
			if absf(x)>2.1 and z> -22.6: continue
			var panel := PackedVector2Array([Vector2(xs[ix],zs[iz]),Vector2(xs[ix+1],zs[iz]),Vector2(xs[ix+1],zs[iz+1]),Vector2(xs[ix],zs[iz+1])])
			for piece in Geometry2D.clip_polygons(panel,circle):
				_flat_polygon_prism(piece,GROUND_FLOOR,-2.15,marble).name = "SealedLowerFloor"
	# Solid outer landings follow the facade instead of stopping short of it.
	for side in [-1.0,1.0]:
		var outer := 7.72 if side<0 else 7.55
		for segment in range(12):
			var a: float = side*lerpf(4.4,outer,segment/12.0)
			var b: float = side*lerpf(4.4,outer,(segment+1)/12.0)
			var lo := minf(a,b)
			var hi := maxf(a,b)
			var za := -sqrt(OUTER_RADIUS*OUTER_RADIUS-lo*lo)+0.02
			var zb := -sqrt(OUTER_RADIUS*OUTER_RADIUS-hi*hi)+0.02
			_flat_polygon_prism(PackedVector2Array([Vector2(lo,-22.6),Vector2(hi,-22.6),Vector2(hi,zb),Vector2(lo,za)]),-0.9,-2.15,marble).name = "CurvedSideLanding"
	for node in get_children().slice(first): node.reparent(assembly,false)

func _make_front_stair_supports(side: float,tag: String,granite: Material,cap: Material) -> void:
	# Deep stringers have stepped upper edges and an open underside.
	for flight in [Vector4(-33,-28,-0.9,2.45),Vector4(-26.7,-23,1.55,2.45)]:
		var steps := int(ceil(flight.w/0.16))
		var depth: float = (flight.y-flight.x)/steps
		for step in range(steps):
			var top: float = flight.z+flight.w*(step+1)/steps
			var z: float = flight.x+depth*(step+0.5)
			_box(Vector3(side*4.23,top-0.40,z),Vector3(0.34,0.80,depth+0.012),granite).name = tag+"GraniteStringer"
			_box(Vector3(side*4.23,top+0.014,z),Vector3(0.40,0.028,depth+0.018),cap,0,false)
	_box(Vector3(side*4.23,1.15,-27.35),Vector3(0.34,0.80,1.3),granite)
	_box(Vector3(side*4.23,1.564,-27.35),Vector3(0.40,0.028,1.3),cap,0,false)
	_box(Vector3(side*4.23,3.60,-21.4),Vector3(0.34,0.80,3.2),granite)
	_box(Vector3(side*4.23,4.014,-21.4),Vector3(0.40,0.028,3.2),cap,0,false)
	# Three fluted piers in approach order. The doorway turn is between 2 and 3;
	# the restored lateral steps sit behind pier 3, nearest the facade.
	var pier_index := 0
	for pier in [Vector2(-27.35,1.17),Vector2(-25.3,2.10),Vector2(-22.9,3.58)]:
		pier_index += 1
		var support := Node3D.new()
		support.name = "Front%sPier_%d" % [tag,pier_index]
		add_child(support)
		var pier_first := get_child_count()
		var bottom := -1.70
		_box(Vector3(side*3.85,bottom-0.02,pier.x),Vector3(0.92,0.20,0.92),granite).name = "Base"
		_box(Vector3(side*3.85,(bottom+pier.y)/2,pier.x),Vector3(0.62,pier.y-bottom,0.62),granite).name = "Shaft"
		_box(Vector3(side*3.85,pier.y+0.06,pier.x),Vector3(0.85,0.12,0.85),cap).name = "Capital"
		for offset in [-0.22,-0.11,0.0,0.11,0.22]:
			_box(Vector3(side*4.17,(bottom+pier.y)/2,pier.x+offset),Vector3(0.028,pier.y-bottom-0.16,0.038),paving,0,false)
		for node in get_children().slice(pier_first): node.reparent(support,false)

func _make_front_left_stair_side() -> void:
	# Looking at the front (+Z), the photograph's left side is positive X.
	var assembly := Node3D.new()
	assembly.name = "FrontLeftStonePassage"
	add_child(assembly)
	var first := get_child_count()
	var granite := _textured_material("stone",Color("878c8c"),0.82)
	var cap := _textured_material("stone",Color("a9adab"),0.52)
	_make_front_stair_supports(1.0,"Left",granite,cap)
	# Like the main stair: a short flight, level landing, then another flight.
	_stair_flight(5.88,-0.9,-32,-30.5,-0.45,2.56,0,0,cap,-2.15)
	_box(Vector3(5.88,-1.75,-30),Vector3(2.56,0.80,1.0),cap).name = "LeftPassageIntermediateLanding"
	_stair_flight(5.88,-1.35,-29.5,-28,-0.45,2.56,0,0,cap,-2.15)
	# Retaining wall with wide coping separates the route from the paving.
	_box(Vector3(7.35,-1.29,-24.5),Vector3(0.38,1.58,7.0),granite).name = "LeftPassageRetainingWall"
	_box(Vector3(7.35,-0.486,-24.5),Vector3(0.52,0.05,7.0),cap)
	_terrain_patch(PackedVector3Array([Vector3(7.16,-0.9,-32),Vector3(7.54,-0.9,-32),Vector3(7.54,-0.5,-28),Vector3(7.16,-0.5,-28)]),1.18,granite)
	_terrain_patch(PackedVector3Array([Vector3(7.09,-0.88,-32),Vector3(7.61,-0.88,-32),Vector3(7.61,-0.475,-28),Vector3(7.09,-0.475,-28)]),0.05,cap)
	# Courtyard-height arrival for the restored lateral doorway steps.
	# Stop the inner curb before the turn so the lower doorway stays accessible.
	_box(Vector3(4.55,-1.53,-26.4),Vector3(0.30,0.54,3.2),granite)
	_box(Vector3(4.45,-1.775,-28.6),Vector3(0.28,0.01,7.0),_textured_material("stone",Color("4f5553"),1.0),0,false)
	# Stone paving and planting continue outside the retaining wall.
	_box(Vector3(8.65,-0.91,-25.6),Vector3(2.1,0.10,8.4),campus_stone)
	for z in [-28.3,-25.7,-23.1]:
		_shrub(Vector3(9.45,-0.83,z))
		for offset in [-0.25,0.0,0.25]:
			_sphere(Vector3(9.05+offset,-0.49,z-0.40),0.09,_material(Color("d78089")))
	for node in get_children().slice(first): node.reparent(assembly,false)

func _make_front_right_stair_side() -> void:
	# Photo: broad stone foreground, shallow descent near the facade, coping,
	# patterned walk, roses, slender evergreens and bent black light standards.
	var assembly := Node3D.new()
	assembly.name = "FrontRightStonePassage"
	add_child(assembly)
	var first := get_child_count()
	var granite := _textured_material("stone",Color("878c8c"),0.82)
	var cap := _textured_material("stone",Color("8f9694"),0.62)
	_make_front_stair_supports(-1.0,"Right",granite,cap)
	_box(Vector3(-5.92,-1.525,-30.35),Vector3(2.64,1.25,5.3),cap).name = "RightUpperStonePassage"
	_stair_flight(-5.92,-0.9,-27.7,-26.5,-0.45,2.64,0,0,cap,-2.15)
	_box(Vector3(-5.92,-1.75,-26.05),Vector3(2.64,0.80,0.9),cap).name = "RightPassageIntermediateLanding"
	_stair_flight(-5.92,-1.35,-25.6,-24.4,-0.45,2.64,0,0,cap,-2.15)
	# Broad polished coping remains at garden level beside the sunken floor.
	_box(Vector3(-7.48,-1.25,-27.6),Vector3(0.42,1.5,10.8),granite).name = "RightPassageRetainingWall"
	_box(Vector3(-7.48,-0.48,-27.6),Vector3(0.64,0.08,10.8),cap)
	_box(Vector3(-4.54,-1.53,-26.4),Vector3(0.28,0.54,3.2),granite)
	_box(Vector3(-4.54,-1.23,-26.4),Vector3(0.34,0.06,3.2),cap,0,false)
	# Subtle joints define the large rectangular stone slabs visible in the photo.
	for z in [-32.1,-30.5,-28.9]:
		_box(Vector3(-5.92,-0.896,z),Vector3(2.62,0.005,0.012),paving,0,false)
	_box(Vector3(-5.92,-0.895,-30.35),Vector3(0.012,0.005,5.3),paving,0,false)
	# Multicolour paving runs outside the coping and joins the facade walkway.
	_box(Vector3(-8.96,-0.91,-26.6),Vector3(2.28,0.10,12.8),campus_stone).name = "RightGardenPaving"
	_box(Vector3(-8.8,-0.91,-19.8),Vector3(5.6,0.10,1.2),campus_stone)
	var lawn := _textured_material("grass",Color("51633a"),1.0)
	_box(Vector3(-13.45,-0.91,-26.1),Vector3(6.7,0.10,11.8),lawn).name = "RightRoseGarden"
	_reference_garden_grass(Vector3(-16.8,-0.84,-32),Vector2(6.7,11.8))
	# Roses line the walk and cross the lawn, rather than sitting on the paving.
	for i in range(13):
		_reference_rose_bush(Vector3(-10.43,-0.84,-31.4+i*0.83),220+i)
	for i in range(7):
		_reference_rose_bush(Vector3(-11.3-i*0.72,-0.84,-25.2),260+i)
	for point in [Vector3(-11.4,-0.84,-28.3),Vector3(-12.1,-0.84,-22.3),Vector3(-15.0,-0.84,-21.7)]:
		_reference_conifer(point)
	for z in [-29.0,-23.3]:
		var foot := Vector3(-9.88,-0.85,z)
		_box(foot+Vector3(0,0.025,0),Vector3(0.24,0.05,0.24),dark,0,false)
		_beam(foot,foot+Vector3(0,2.75,0),0.045,dark)
		_beam(foot+Vector3(0,2.75,0),foot+Vector3(-0.65,3.4,0),0.045,dark)
		_beam(foot+Vector3(-0.65,3.4,0),foot+Vector3(0.12,4.55,0),0.065,dark)
		_beam(foot+Vector3(-0.50,3.62,0),foot+Vector3(0.12,4.55,0),0.10,dark)
		_beam(foot+Vector3(-0.45,3.59,-0.065),foot+Vector3(0.13,4.45,-0.065),0.022,glow)
	# Low stone terrace behind the planting, matching the garden's far edge.
	_box(Vector3(-13.45,-0.60,-20.15),Vector3(6.7,0.6,0.35),granite)
	_box(Vector3(-13.45,-0.28,-20.15),Vector3(6.82,0.06,0.48),cap)
	for node in get_children().slice(first): node.reparent(assembly,false)

func _reference_rose_bush(origin: Vector3,seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var foliage := _material(Color("384e29"),0.95)
	var pink := _material(Color("e5a0ae"),0.85)
	var blush := _material(Color("f1c1b4"),0.85)
	for stem in range(7):
		var tip := origin+Vector3(rng.randf_range(-0.28,0.28),rng.randf_range(0.28,0.64),rng.randf_range(-0.25,0.25))
		_beam(origin,tip,0.009,foliage)
		for leaf in range(4):
			var centre := origin.lerp(tip,0.2+leaf*0.18)+Vector3(0.07 if leaf%2==0 else -0.07,0,0)
			var blade := _sphere(centre,0.065,foliage)
			blade.scale = Vector3(1.0,0.25,1.7)
			blade.rotation.y = rng.randf_range(0,TAU)
		for petal in range(5):
			var angle := petal*TAU/5
			var bloom := _sphere(tip+Vector3(cos(angle)*0.045,0,sin(angle)*0.045),0.043,pink if stem%2 else blush)
			bloom.scale.y = 0.48
		_sphere(tip+Vector3.UP*0.015,0.024,blush)

func _reference_conifer(origin: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(origin.z)*107)
	_beam(origin,origin+Vector3.UP*2.9,0.032,wood)
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 6
	mesh.rings = 4
	var foliage := MultiMesh.new()
	foliage.transform_format = MultiMesh.TRANSFORM_3D
	foliage.use_colors = true
	foliage.mesh = mesh
	foliage.instance_count = 1500
	for i in range(foliage.instance_count):
		var y := rng.randf_range(0.16,3.05)
		var angle := rng.randf_range(0,TAU)
		var radius := (0.035+0.39*pow(1.0-y/3.15,0.65))*sqrt(rng.randf())
		var centre := Vector3(cos(angle)*radius,y,sin(angle)*radius)
		var basis := Basis.from_euler(Vector3(rng.randf_range(-0.3,0.3),angle,rng.randf_range(-0.35,0.35))).scaled(Vector3(0.025,0.13,0.038)*rng.randf_range(0.7,1.35))
		foliage.set_instance_transform(i,Transform3D(basis,centre))
		foliage.set_instance_color(i,Color("637b3d")*rng.randf_range(0.65,1.16))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = foliage
	instance.position = origin
	var mat := _material(Color.WHITE,1.0)
	mat.vertex_color_use_as_albedo = true
	instance.material_override = mat
	add_child(instance)

func _reference_garden_grass(origin: Vector3,size: Vector2) -> void:
	var blade := SurfaceTool.new()
	blade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in [Vector3(-0.015,0,0),Vector3(0.015,0,0),Vector3(0.02,0.12,0)]:
		blade.set_normal(Vector3.FORWARD)
		blade.add_vertex(vertex)
	var blades := MultiMesh.new()
	blades.transform_format = MultiMesh.TRANSFORM_3D
	blades.use_colors = true
	blades.mesh = blade.commit()
	blades.instance_count = 5000
	var rng := RandomNumberGenerator.new()
	rng.seed = 2222
	for i in range(blades.instance_count):
		var basis := Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*rng.randf_range(0.55,1.0))
		blades.set_instance_transform(i,Transform3D(basis,Vector3(rng.randf()*size.x,0,rng.randf()*size.y)))
		blades.set_instance_color(i,Color("526d37")*rng.randf_range(0.75,1.15))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = blades
	instance.position = origin
	var mat := _material(Color.WHITE,1.0)
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = mat
	add_child(instance)

func _make_entrances() -> void:
	# One broad entrance stair inherits the former side flight profile,
	# with an intermediate landing and dark glass balustrades.
	var frontage := Node3D.new()
	frontage.name = "FrontEntranceStairs"
	add_child(frontage)
	var front_first := get_child_count()
	_box(Vector3(0,3.85,-21.4),Vector3(8.6,0.3,3.2),marble,0,false)
	_box(Vector3(0,3.85,-21),Vector3(8.6,0.3,2.4),marble).visible = false
	_stair_flight(0,-0.9,-33,-28,2.45,8.4,1.3)
	_box(Vector3(0,1.41,-27.35),Vector3(8.4,0.28,1.3),marble,0,false)
	_stair_flight(0,1.55,-26.7,-23,2.45,8.4,0.8)
	for side in [-1.0,1.0]:
		var x: float = side*4.25
		_glass_guard(Vector3(x,-0.9,-33),Vector3(x,1.55,-28))
		_glass_guard(Vector3(x,1.55,-28),Vector3(x,1.55,-26.7))
		_glass_guard(Vector3(x,1.55,-26.7),Vector3(x,4,-23))
		_glass_guard(Vector3(x,4,-23),Vector3(x,4,-19.85))
	for node in get_children().slice(front_first): node.reparent(frontage,false)
	_make_front_left_stair_side()
	_make_front_right_stair_side()
	_make_front_forecourt_foundation()
	# Sunken front forecourt: descend from courtyard -0.9 to the doorway at -1.8.
	# Door, vestibule and the entire ground floor share one level; no indoor steps.
	for side in [-1.0,1.0]:
		_box(Vector3(side*1.5,-0.4,-20.25),Vector3(0.12,2.8,0.25),door_wood)
		_box(Vector3(side*1.28,-0.45,-20.6),Vector3(0.08,2.7,0.8),bronze)
		_box(Vector3(side*2.05,-0.9,-20),Vector3(1.1,1.8,0.45),limestone)
	_box(Vector3(0,1.05,-20.25),Vector3(3.1,0.16,0.25),door_wood)
	_box(Vector3(0,2.25,-20),Vector3(3,2.3,0.45),limestone)
	_label("0-QAVAT KIRISH",Vector3(0,1.4,-20.4),PI,0.004)
	for side in [-1.0,1.0]:
		var approach := Node3D.new()
		approach.name = "FrontLowerSideStairs_%d" % int(side)
		approach.position = Vector3(side*2.1,0,-21.4)
		approach.rotation.y = side*PI/2
		add_child(approach)
		var first := get_child_count()
		_stair_flight(0,-1.8,0,2.3,0.9,2.4,0.0,0.0,marble,-2.15,side)
		for node in get_children().slice(first): node.reparent(approach,false)
	# The longitudinal passage turns beneath the flight and enters between jambs.
	# Keep a central opening so it coexists with both original lateral stairs.
	for x in [-3.05,3.05]:
		_box(Vector3(x,-1.35,-22.75),Vector3(3.7,0.9,0.2),limestone)
	# Rear door is flush with the round wall; the long projecting porch is removed.
	_box(Vector3(0,GROUND_FLOOR-0.14,20.7),Vector3(4.2,0.28,2.4),marble)
	_stair_flight(0,GROUND_FLOOR,21.9,24.0,0.9,4.2,0.8)
	for side in [-1.0,1.0]:
		_box(Vector3(side*1.55,GROUND_FLOOR+1.4,20.4),Vector3(0.08,2.8,1.0),bronze)
		_box(Vector3(side*2.05,GROUND_FLOOR/2,20),Vector3(1.1,-GROUND_FLOOR,0.45),limestone)
	_label("ORQA KIRISH",Vector3(0,3.25,20.3),0,0.005)
	_box(Vector3(0,3.85,21.2),Vector3(5.5,0.3,3.2),marble)
	# Mirrored L-shaped stairs: approach toward the wall, turn on a landing,
	# then rise sideways to the common first-floor entrance (reference photo).
	for side in [-1.0,1.0]:
		var x: float = side*9.4
		_stair_flight(x,-0.9,28.9,22.7,2.3,2.2)
		_box(Vector3(x,1.26,21.6),Vector3(2.4,0.28,2.2),paving)
		_box(Vector3(x,0.18,21.6),Vector3(0.38,2.16,0.38),limestone)
		_stair_railing(Vector3(x-1.1,-0.9,28.9),Vector3(x-1.1,1.4,22.7))
		_stair_railing(Vector3(x+1.1,-0.9,28.9),Vector3(x+1.1,1.4,22.7))
		_stair_railing(Vector3(side*10.6,1.4,22.7),Vector3(side*10.6,1.4,20.5))
		_stair_railing(Vector3(side*10.6,1.4,20.5),Vector3(side*8.2,1.4,20.5))
		var assembly := Node3D.new()
		assembly.position = Vector3(side*2.75,0,21.6)
		assembly.rotation.y = side*PI/2
		add_child(assembly)
		var first := get_child_count()
		_stair_flight(0,1.4,5.45,0,2.6,2.2)
		for edge in [-1.1,1.1]:
			_stair_railing(Vector3(edge,1.4,5.45),Vector3(edge,4,0))
		for node in get_children().slice(first): node.reparent(assembly,false)
		_box(Vector3(side*2.45,1.45,21.0),Vector3(0.30,4.6,0.36),limestone)
	# Close the courtyard-facing edge; both lateral stair arrivals stay open.
	_stair_railing(Vector3(-2.65,4,22.75),Vector3(2.65,4,22.75))
	for x in [-2.65,2.65]:
		_beam(Vector3(x,4,22.75),Vector3(x,5.05,22.75),0.04,metal)
	_box(Vector3(0,4.55,22.75),Vector3(5.3,1.1,0.08),metal).visible = false
	# Pale recessed rectangular portal and cornice above the rear landing.
	for x in [-2.45,2.45]:
		_box(Vector3(x,6.0,20.36),Vector3(0.40,4.0,0.46),limestone,0,false)
		_box(Vector3(x,6.0,20.64),Vector3(0.12,3.75,0.13),cream,0,false)
		_box(Vector3(x,4.16,20.36),Vector3(0.63,0.32,0.58),cream,0,false)
	for y in [7.86,8.05,8.24]:
		_box(Vector3(0,y,20.4),Vector3(5.8+(y-7.86),0.16,0.72),cream,0,false)
	for x in [-1.74,1.74]:
		_box(Vector3(x,5.55,20.42),Vector3(0.12,2.8,0.22),cream,0,false)
	_label("1-QAVAT",Vector3(0,7.3,20.35),0,0.005)
	for z in range(11,20):
		for rib in range(5):
			_box(Vector3(-0.2+rib*0.1,GROUND_FLOOR+0.025,z),Vector3(0.025,0.018,0.65),_material(Color("c9af62")),0,false).name = "GroundGuidance_%d_%d" % [z,rib]

func _make_gallery_air_conditioners() -> void:
	# Cassette units sit flush under each gallery ceiling, facing the floor below.
	for level in range(FLOOR_COUNT):
		for index in range(8):
			var unit := Node3D.new()
			unit.name = "GalleryAirConditioner_%d_%d" % [level,index]
			add_child(unit)
			var first := get_child_count()
			var center := _polar(8.7,TAU*(index+0.25)/8.0,floor_height(level+1)-0.35)
			_box(center,Vector3(1.15,0.12,1.15),cream,0,false)
			_box(center+Vector3(0,-0.065,0),Vector3(0.65,0.018,0.65),dark,0,false)
			for strip in range(9):
				_box(center+Vector3(0,-0.079,-0.29+strip*0.0725),Vector3(0.63,0.012,0.018),metal,0,false)
			for side in [-1.0,1.0]:
				_box(center+Vector3(side*0.46,-0.065,0),Vector3(0.09,0.015,0.83),dark,0,false)
				_box(center+Vector3(0,-0.065,side*0.46),Vector3(0.83,0.015,0.09),dark,0,false)
			for node in get_children().slice(first): node.reparent(unit,false)

func _make_dome() -> void:
	var roof_mat := _material(Color(0.16,0.38,0.64,0.88),0.22)
	roof_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	roof_mat.metallic = 0.5
	var opening_radius := 1.5
	var max_angle := acos(opening_radius/DOME_RADIUS)
	var opening_height := DOME_BASE+DOME_RISE*sin(max_angle)
	var oculus := Node3D.new()
	oculus.name = "DomeOculus"
	add_child(oculus)
	# Raised blue skylight silhouette remains visible from the front courtyard.
	for i in range(48):
		var a := TAU*i/48
		var b := TAU*(i+1)/48
		_box(_polar(DOME_RADIUS,(a+b)/2,(ROOF_HEIGHT+DOME_BASE)/2),Vector3(2*DOME_RADIUS*sin(PI/48),DOME_BASE-ROOF_HEIGHT,0.08),glass,-(a+b)/2-PI/2,true)
		_beam(_polar(DOME_RADIUS,a,ROOF_HEIGHT),_polar(DOME_RADIUS,a,DOME_BASE),0.055,bronze)
		for ring in range(8):
			var t0 := max_angle*ring/8
			var t1 := max_angle*(ring+1)/8
			var r0 := DOME_RADIUS*cos(t0)
			var r1 := DOME_RADIUS*cos(t1)
			var y0 := DOME_BASE+DOME_RISE*sin(t0)
			var y1 := DOME_BASE+DOME_RISE*sin(t1)
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			_quad(st,_polar(r0,a,y0),_polar(r1,a,y1),_polar(r1,b,y1),_polar(r0,b,y0))
			var mesh := MeshInstance3D.new()
			mesh.mesh = st.commit()
			mesh.material_override = roof_mat
			add_child(mesh)
			var body := StaticBody3D.new()
			body.name = "DomeGlassPanel_%d_%d" % [i,ring]
			var shape := ConvexPolygonShape3D.new()
			var points := PackedVector3Array([_polar(r0,a,y0),_polar(r1,a,y1),_polar(r1,b,y1),_polar(r0,b,y0)])
			for point in points.duplicate(): points.append(point-Vector3(0,0.06,0))
			shape.points = points
			var collision := CollisionShape3D.new()
			collision.shape = shape
			body.add_child(collision)
			add_child(body)
			if i%3==0: _beam(_polar(r0,a,y0+0.02),_polar(r1,a,y1+0.02),0.025,metal)
			if ring in [1,3,5]: _beam(_polar(r0,a,y0+0.02),_polar(r0,b,y0+0.02),0.02,metal)

		var first := get_child_count()
		_wedge(opening_radius,opening_radius+0.16,a,b,opening_height+0.04,0.12,metal,true)
		for node in get_children().slice(first): node.reparent(oculus,false)

func _make_lift() -> void:
	lift = Node3D.new()
	lift.set_script(preload("res://scripts/lift.gd"))
	lift.position = LIFT_CENTER
	lift.rotation.y = -PI/2
	add_child(lift)
	# Facing inward from the rear (+Z), negative X is the visitor's left.
	for level in range(FLOOR_COUNT):
		var h := floor_height(level)
		_box(Vector3(-4.4,h-0.14,14.45),Vector3(2.5,0.28,1.1),marble)
		_fill_lift_rear(level,h,floor_height(level+1)-h)
	# Doorway in the rear corridor's left wall is carved by replacing its lift-facing piece.
	for node in get_children():
		if node is StaticBody3D and absf(node.position.x+2.2)<0.01 and absf(node.position.z-15.25)<0.01:
			var wall_size: Vector3 = (node.get_child(0).mesh as BoxMesh).size
			var h: float = node.position.y-wall_size.y/2
			node.queue_free()
			_box(Vector3(-2.2,h+(wall_size.y+2.9)/2,16.2),Vector3(0.16,wall_size.y-2.9,5.2),cream)

func _fill_lift_rear(level: int,h: float,height: float) -> void:
	# Fill only behind the shaft; trim the back edge to the circular facade.
	var footprint := PackedVector2Array([Vector2(-5.9,17.78),Vector2(-2.15,17.78)])
	for x in [-2.15,-3.4,-4.7,-5.9]:
		footprint.append(Vector2(x,sqrt(19.8*19.8-x*x)))
	var points := PackedVector3Array()
	for point in footprint: points.append(Vector3(point.x,h+height,point.y))
	for point in footprint: points.append(Vector3(point.x,h,point.y))
	var n := footprint.size()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,n-1):
		_quad(surface,points[0],points[i+1],points[i],points[0])
		_quad(surface,points[n],points[n+i],points[n+i+1],points[n])
	for i in range(n):
		var j := (i+1)%n
		_quad(surface,points[i],points[j],points[j+n],points[i+n])
	var body := StaticBody3D.new()
	body.name = "LiftRearInfill_%d" % level
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = wood
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _link_guard(a: Vector3,b: Vector3) -> void:
	_stair_railing(a,b)
	var points := PackedVector3Array()
	for foot in [a,b]:
		for x in [-0.045,0.045]:
			for y in [-0.08,1.08]: points.append(foot+Vector3(x,y,0))
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _link_foundation() -> void:
	# A filled stone base, rather than an exposed flight floating over ground.
	var points := PackedVector3Array([
		Vector3(-18.2,-0.96,30.5),Vector3(-12.8,-0.96,30.5),
		Vector3(-12.8,2.34,47.5),Vector3(-18.2,2.34,47.5),
		Vector3(-18.2,-1.05,30.5),Vector3(-12.8,-1.05,30.5),
		Vector3(-12.8,-1.05,47.5),Vector3(-18.2,-1.05,47.5)])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(surface,points[0],points[3],points[2],points[1])
	_quad(surface,points[4],points[5],points[6],points[7])
	for i in range(4):
		var j := (i+1)%4
		_quad(surface,points[i],points[j],points[j+4],points[i+4])
	var body := StaticBody3D.new()
	body.name = "StoneStairFoundation"
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = paving
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _make_campus_link() -> void:
	# Walking out of the rear entrance faces +Z: right is the -X stair.
	var link := Node3D.new()
	link.name = "RearCampusLink"
	add_child(link)
	var first := get_child_count()
	var tiles := campus_stone
	var stair := Node3D.new()
	stair.name = "ConnectingStoneStair"
	add_child(stair)
	var stair_first := get_child_count()
	_box(Vector3(-12.7,-0.93,30.0),Vector3(11.0,0.10,2.0),tiles,0,false)
	_stair_flight(-15.5,-0.9,30.5,47.5,3.3,5.4,0.8,0.0,tiles)
	_link_foundation()
	_link_guard(Vector3(-18.25,-0.9,30.5),Vector3(-18.25,2.4,47.5))
	_link_guard(Vector3(-12.75,-0.9,30.5),Vector3(-12.75,2.4,47.5))
	_box(Vector3(-15.5,2.24,47.85),Vector3(5.4,0.32,0.7),tiles,0,false)
	for node in get_children().slice(stair_first): node.reparent(stair,false)
	stair.position.x = 1.5
	_box(Vector3(-34.6,0.75,44.5),Vector3(31.6,3.3,7.4),limestone)
	_box(Vector3(-34.6,2.415,44.5),Vector3(31.6,0.03,7.4),tiles)
	_stair_railing(Vector3(-50.3,2.4,40.8),Vector3(-18.85,2.4,40.8))
	_stair_railing(Vector3(-11.2,2.4,47.5),Vector3(-11.2,2.4,48.2))
	_stair_railing(Vector3(-50.3,2.4,40.8),Vector3(-50.3,2.4,48.3))
	# The stair ends beside the facade corner; turn right across this short link.
	_box(Vector3(-17.75,0.75,47.85),Vector3(2.1,3.3,0.7),limestone).name = "StairToFacadeLanding"
	_box(Vector3(-17.75,2.415,47.85),Vector3(2.1,0.03,0.7),tiles,0,false)
	var neighbour := Node3D.new()
	neighbour.name = "NeighbourBuilding"
	neighbour.set_meta("near_side_x",-36.2)
	add_child(neighbour)
	var neighbour_first := get_child_count()
	# Reference block: three floors, a long pale facade and a roof below the rotunda.
	var base_height := 2.4
	var roof_height := ROOF_HEIGHT-1.6
	var storey_height := (roof_height-base_height)/3.0
	var facade := _textured_material("stone",Color("e8dfc5"),0.92)
	var trim := _material(Color("d9ceb2"),0.92)
	var frame := _material(Color("242c2b"),0.65)
	var pane := _material(Color("253c3e"),0.25)
	var roof_green := _material(Color("50776d"),0.72)
	var wall_height := roof_height-base_height-0.3
	var wall_mid := base_height+wall_height/2.0
	_box(Vector3(-24,0.6,52.5),Vector3(24.4,3.0,8.6),limestone)
	_box(Vector3(-24,2.25,52.5),Vector3(24.4,0.30,8.6),tiles)
	_box(Vector3(-24,roof_height-0.15,52.5),Vector3(24.8,0.30,8.8),roof_green).name = "NeighbourRoof"
	for x in [-36.08,-11.92]:
		_box(Vector3(x,wall_mid,52.5),Vector3(0.24,wall_height,8.2),facade)
	_box(Vector3(-24,wall_mid,56.55),Vector3(24.4,wall_height,0.24),facade)
	# Keep the central doorway open for the connecting raised path.
	_box(Vector3(-30.77,wall_mid,48.45),Vector3(10.94,wall_height,0.25),facade)
	_box(Vector3(-18.35,wall_mid,48.45),Vector3(8.7,wall_height,0.25),facade)
	_box(Vector3(-11.88,wall_mid,48.45),Vector3(0.24,wall_height,0.25),facade)
	var upper_entry := base_height+storey_height
	_box(Vector3(-13,(base_height+upper_entry)/2.0,48.45),Vector3(2.0,upper_entry-base_height,0.25),facade)
	_box(Vector3(-13,(upper_entry+2.8+roof_height-0.3)/2.0,48.45),Vector3(2.0,roof_height-0.3-upper_entry-2.8,0.25),facade)
	_box(Vector3(-24,(5.15+roof_height-0.3)/2.0,48.45),Vector3(2.6,roof_height-0.3-5.15,0.25),facade)
	for level in range(3):
		var base := base_height+level*storey_height
		for bay in range(11):
			var x := -35.0+bay*2.2
			if (level==0 and bay==5) or (level==1 and bay==10): continue
			var window_height := 2.10 if level==2 else 1.65
			var centre := base+1.50
			_box(Vector3(x,centre,48.285),Vector3(1.36,window_height,0.045),pane,0,false).name = "NeighbourWindow_%d_%d" % [level,bay]
			for edge in [-0.70,0.70]:
				_box(Vector3(x+edge,centre,48.205),Vector3(0.075,window_height+0.16,0.10),frame,0,false)
			for edge in [-window_height/2.0,window_height/2.0]:
				_box(Vector3(x,centre+edge,48.205),Vector3(1.47,0.075,0.10),frame,0,false)
			for mullion in [-0.24,0.24]:
				_box(Vector3(x+mullion,centre,48.18),Vector3(0.04,window_height,0.06),frame,0,false)
			_box(Vector3(x,centre+0.42,48.18),Vector3(1.36,0.04,0.06),frame,0,false)
			# Recess outline continues above and below the windows, like the photograph.
			for edge in [-0.88,0.88]:
				_box(Vector3(x+edge,base+storey_height/2.0,48.13),Vector3(0.055,storey_height-0.12,0.14),trim,0,false)
			_box(Vector3(x,base+storey_height-0.12,48.13),Vector3(1.81,0.065,0.14),trim,0,false)
			_box(Vector3(x,centre-window_height/2.0-0.12,48.11),Vector3(1.62,0.12,0.20),cream,0,false)
		for course in range(1,8):
			var y := base+course*storey_height/8.0
			for bay in range(12):
				var x := -36.1+bay*2.2
				_box(Vector3(x,y,48.295),Vector3(0.32,0.018,0.025),trim,0,false)
		if level<2:
			_box(Vector3(-24,base+storey_height,52.5),Vector3(23.9,0.18,7.9),cream).name = "NeighbourFloor_%d" % (level+1)
	for bay in range(12):
		var x := -36.1+bay*2.2
		_box(Vector3(x,wall_mid,48.10),Vector3(0.14,wall_height,0.28),cream,0,false)
	for x in [-36.18,-31.7,-25.1,-18.5,-11.82]:
		_box(Vector3(x,wall_mid,48.03),Vector3(0.26,wall_height,0.37),trim,0,false)
		_box(Vector3(x,roof_height-1.05,47.93),Vector3(0.38,0.22,0.15),cream,0,false)
		_beam(Vector3(x,-0.8,47.84),Vector3(x,roof_height-0.8,47.84),0.035,roof_green)
	# Broad cornice and shallow metal roof with vents.
	_box(Vector3(-24,roof_height-0.06,48.03),Vector3(24.9,0.12,0.24),roof_green,0,false)
	_box(Vector3(-24,roof_height-0.64,48.12),Vector3(24.9,0.74,0.44),facade,0,false)
	_box(Vector3(-24,roof_height-1.05,48.02),Vector3(25.0,0.13,0.56),trim,0,false)
	for x in [-33,-28,-20,-15]:
		_box(Vector3(x,roof_height+0.35,53),Vector3(0.38,0.7,0.38),trim)
		_box(Vector3(x,roof_height+0.72,53),Vector3(0.52,0.07,0.52),roof_green,0,false)
	for x in [-25.3,-22.7]:
		_box(Vector3(x,3.77,48.25),Vector3(0.10,2.75,0.30),frame)
	# Shallow curved brown canopy above the central open entry.
	var canopy := _material(Color("71503c"),0.78)
	for strip in range(12):
		var x := -25.45+(strip+0.5)*2.9/12.0
		var arch := 0.22*(1.0-pow((x+24)/1.45,2))
		_box(Vector3(x,5.30+arch,47.98),Vector3(2.9/12.0,0.10,1.15),canopy,0,false)
	for side in [-1.0,1.0]:
		_box(Vector3(-24+side*0.97,3.77,48.72),Vector3(0.09,2.68,0.95),frame,side*0.18)
	# Narrow exterior stair to the left upper doorway, as in the reference.
	var side_stair := Node3D.new()
	side_stair.name = "NeighbourExteriorStair"
	add_child(side_stair)
	var side_first := get_child_count()
	_stair_flight(0,base_height,0,5.0,storey_height,1.2,0.8,0,cream)
	_stair_railing(Vector3(-0.66,base_height,0),Vector3(-0.66,upper_entry,5))
	_stair_railing(Vector3(0.66,base_height,0),Vector3(0.66,upper_entry,5))
	for node in get_children().slice(side_first): node.reparent(side_stair,false)
	side_stair.position = Vector3(-18,0,43.5)
	side_stair.rotation.y = PI/2.0
	_box(Vector3(-18,0.75,44.0),Vector3(1.4,3.3,2.6),limestone)
	_box(Vector3(-13,upper_entry-0.12,46.29),Vector3(1.9,0.24,4.42),cream)
	_stair_railing(Vector3(-12.02,upper_entry,43.5),Vector3(-12.02,upper_entry,48.2))
	_stair_railing(Vector3(-13.98,upper_entry,44.2),Vector3(-13.98,upper_entry,48.2))
	for x in [-13.95,-12.05]:
		_box(Vector3(x,upper_entry+1.4,48.20),Vector3(0.09,2.8,0.22),frame)
	_box(Vector3(-13.75,upper_entry+1.35,48.95),Vector3(0.09,2.7,0.95),frame,0.18)
	for strip in range(8):
		var x := -14.12+(strip+0.5)*2.24/8.0
		_box(Vector3(x,upper_entry+2.96+0.17*(1.0-pow((x+13)/1.12,2)),48.0),Vector3(0.28,0.08,1.05),canopy,0,false)
	for node in get_children().slice(neighbour_first): node.reparent(neighbour,false)
	# Seven metres toward the first tree beside the near end of the reference block.
	neighbour.scale.x = 31.4/24.4
	# Widen away from the broad stair, keeping its adjacent building corner fixed.
	neighbour.position.x = -7.0-11.8*(1.0-neighbour.scale.x)
	_make_link_garden()
	for node in get_children().slice(first): node.reparent(link,false)

	# Turn the entire assembly clockwise from its approach, keeping the stair foot fixed.
	var pivot := Vector3(-15.5,0,30.5)
	link.rotation.y = -PI/2
	link.position = pivot-link.basis*pivot

func _make_link_garden() -> void:
	# The stair's right side has a planted courtyard below the raised walkway.
	var garden := Node3D.new()
	garden.name = "LinkSideGarden"
	add_child(garden)
	var first := get_child_count()
	var lawn := _textured_material("grass",Color("607642"),1.0)
	_box(Vector3(-23.25,-0.86,37.7),Vector3(9.4,0.16,13.8),lawn).name = "LawnBed"
	_box(Vector3(-23.25,-0.81,30.55),Vector3(10.0,0.16,0.5),paving)
	_box(Vector3(-28.2,-0.81,37.7),Vector3(0.50,0.16,14.8),paving)
	_box(Vector3(-17.65,-0.81,37.7),Vector3(1.80,0.16,14.0),campus_stone)
	_box(Vector3(-23.25,0.61,45.0),Vector3(9.5,2.82,0.28),paving).name = "GardenRetainingWall"
	_tree(Vector3(-27.0,-0.77,34.0),1515)
	for point in [Vector3(-27,-0.77,43.5),Vector3(-20,-0.77,43.7),Vector3(-27,-0.77,32.5)]:
		_shrub(point+Vector3(0,0.4,0))
	for x in [-26.0,-21.0]:
		for z in [33.5,40.5]:
			_box(Vector3(x,-0.74,z),Vector3(0.07,0.12,0.07),dark,0,false)
	for node in get_children().slice(first): node.reparent(garden,false)

func _make_roof_ladder() -> void:
	var ladder := Node3D.new()
	ladder.name = "RoofAccessLadder"
	# Front view faces +Z, so its left-hand facade is +X.
	ladder.rotation.y = PI
	add_child(ladder)
	var first := get_child_count()
	for z in [-0.48,0.48]:
		_beam(Vector3(-20.55,-0.9,z),Vector3(-20.55,17.1,z),0.055,metal)
		_beam(Vector3(-20.55,17.1,z),Vector3(-19.2,17.1,z),0.055,metal)
		for y in [0.0,4.0,8.0,12.0,15.7]:
			_beam(Vector3(-20.55,y,z),Vector3(-19.85,y,z),0.04,dark)
	for step in range(55):
		var y := -0.65+step*0.31
		_beam(Vector3(-20.55,y,-0.48),Vector3(-20.55,y,0.48),0.045,metal)
	_box(Vector3(-19.85,15.92,0),Vector3(1.9,0.26,1.1),metal)
	for node in get_children().slice(first): node.reparent(ladder,false)

func near_roof_ladder(point: Vector3) -> bool:
	var exterior := point.x<22.0 and point.x>20.6
	var roof_exit := point.y>15.75 and point.x<22.0 and point.x>18.7
	return (exterior or roof_exit) and absf(point.z)<0.85 and point.y>-1.3 and point.y<16.5

func _make_campus() -> void:
	var asphalt := _textured_material("stone",Color("53575a"),0.98)
	var grass := _textured_material("grass",Color("62694a"),1.0)
	# Circular campus ground excludes the building and both sunken doorways.
	for i in range(SEGMENTS):
		_wedge(20.0,90.0,TAU*i/SEGMENTS,TAU*(i+1)/SEGMENTS,-0.9,0.36,asphalt,true)
	for i in range(SEGMENTS):
		_wedge(20.5,23.0,TAU*i/SEGMENTS,TAU*(i+1)/SEGMENTS,-0.86,0.09,campus_stone,true)
	for side in [-1.0,1.0]:
		if side<0: _box(Vector3(side*36,-0.88,0),Vector3(18,0.08,90),grass)
		if side>0:
			# Leave the descending passage's courtyard threshold free of lawn.
			_box(Vector3(13,-0.88,-38.5),Vector3(13,0.08,13),grass)
			_box(Vector3(13.6,-0.88,-31.5),Vector3(11.8,0.08,1),grass)
		else:
			_box(Vector3(-13,-0.88,-39),Vector3(13,0.08,12),grass)
			_box(Vector3(-14.85,-0.88,-32),Vector3(9.3,0.08,2),grass)
		for z in ([-46.0,-31.0,-14.0,3.0,42.0] if side<0 else []):
			_tree(Vector3(side*(31.0+fmod(absf(z),6.0)),-0.83,z),int(absf(z)*31+side*7))
		for z in ([-37.0,-12.0,13.0,38.0] if side<0 else []):
			_beam(Vector3(side*25,-0.9,z),Vector3(side*25,4.7,z),0.065,dark)
			_box(Vector3(side*25,4.7,z),Vector3(0.6,0.1,0.28),glow,0,false)
	# Low stone planters/benches replace floating-looking wooden cover cubes.
	for point in [Vector3(7,-0.9,35),Vector3(-7,-0.9,38),Vector3(-25,-0.9,-15)]:
		_box(point+Vector3(0,0.42,0),Vector3(2.6,0.84,1.1),limestone)
		for offset in [-0.8,0.0,0.8]: _shrub(point+Vector3(offset,0.85,0))

static func side_lane_height(z: float) -> float:
	# From the rear to the front courtyard: a gradual 0.8 m climb over 40 m.
	return -0.9+clampf((20.0-z)/40.0,0.0,1.0)*0.8

static func side_lane_corner_height(z: float,angle: float) -> float:
	# A short gentle exit joins the raised front end back to the entrance courtyard.
	return lerpf(-0.1,-0.9,clampf((-angle-1.0)/0.2,0.0,1.0)) if angle<-1.0 else side_lane_height(z)

func _terrain_patch(corners: PackedVector3Array,depth: float,mat: Material) -> Node3D:
	var points := corners.duplicate()
	for point in corners: points.append(point-Vector3.UP*depth)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(st,points[0],points[3],points[2],points[1])
	_quad(st,points[4],points[5],points[6],points[7])
	for i in range(4): _quad(st,points[i],points[(i+1)%4],points[(i+1)%4+4],points[i+4])
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = mat
	var body := StaticBody3D.new()
	body.add_child(mesh)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _make_rear_reference_house() -> void:
	# A low cream service house faces the rear ground-floor exit. Its rear wall
	# is the existing perimeter wall at Z=50, extended upward to meet the roof.
	var house := Node3D.new()
	house.name = "RearReferenceHouse"
	add_child(house)
	var first := get_child_count()
	var wall := _textured_material("stone",Color("c9c0a4"),0.94)
	var plinth := _textured_material("stone",Color("737773"),0.94)
	var roof := _material(Color("4c655d"),0.68)
	var frame := _material(Color("39443e"),0.55)
	var pane := _material(Color("788581"),0.35)
	var recess := _material(Color("77796a"),0.94)
	# The apron and interior sit slightly above the courtyard, with no threshold lip.
	_box(Vector3(0,-0.98,41.0),Vector3(23.0,0.20,3.0),campus_stone).name = "HouseApron"
	_box(Vector3(0,-0.98,46.15),Vector3(21.5,0.20,7.3),paving).name = "HouseFloor"
	for side in [-1.0,1.0]:
		_box(Vector3(side*6.6,1.04,42.5),Vector3(8.8,3.88,0.30),wall)
		_box(Vector3(side*6.6,-0.70,42.32),Vector3(8.8,0.34,0.12),plinth,0,false)
		_box(Vector3(side*10.87,1.10,46.34),Vector3(0.26,4.0,7.67),wall)
		_box(Vector3(side*2.16,0.50,43.20),Vector3(0.20,2.76,1.4),wall)
		_box(Vector3(side*10.9,1.13,42.22),Vector3(0.38,4.02,0.32),wall)
		# Rainwater pipes and eave trim match the dark green roof edge in the photo.
		_beam(Vector3(side*10.48,-0.77,42.20),Vector3(side*10.48,3.11,42.20),0.048,roof)
	_box(Vector3(0,2.48,42.50),Vector3(4.4,1.0,0.3),wall).name = "RecessedEntranceLintel"
	_box(Vector3(0,2.12,43.18),Vector3(4.25,0.16,1.4),wall)
	_box(Vector3(0,2.60,50),Vector3(21.5,1.60,0.35),wall).name = "SharedRearWallExtension"
	# Open dark double leaves reveal the shaded entrance instead of a flat black panel.
	for side in [-1.0,1.0]:
		_box(Vector3(side*1.35,0.47,43.76),Vector3(0.10,2.65,1.02),frame,side*0.20)
		_box(Vector3(side*1.295,0.65,43.72),Vector3(0.015,1.20,0.60),pane,side*0.20,false)
	_box(Vector3(0,1.95,43.88),Vector3(2.8,0.12,0.16),frame)
	_box(Vector3(0,1.0,49.78),Vector3(4.0,3.7,0.025),recess,0,false)
	# One broad window to the left and two narrow windows to the right.
	for spec in [Vector2(6.75,1.85),Vector2(-4.75,1.05),Vector2(-8.25,1.05)]:
		var x: float = spec.x
		var width: float = spec.y
		_box(Vector3(x,0.80,42.30),Vector3(width,2.20,0.035),pane,0,false)
		for edge in [-1.0,1.0]:
			_box(Vector3(x+edge*(width/2+0.045),0.80,42.24),Vector3(0.075,2.34,0.10),frame,0,false)
		for y in [-0.34,1.38,1.94]:
			_box(Vector3(x,y,42.24),Vector3(width+0.16,0.075,0.10),frame,0,false)
		_box(Vector3(x,0.50,42.23),Vector3(0.07,1.65,0.10),frame,0,false)
		_box(Vector3(x,-0.40,42.17),Vector3(width+0.28,0.09,0.28),limestone,0,false)
	# Horizontal plaster joints, a shallow green roof and a continuous gutter.
	for y in [-0.10,0.45,1.00,1.55,2.10,2.65]:
		for side in [-1.0,1.0]:
			_box(Vector3(side*6.6,y,42.344),Vector3(8.8,0.012,0.007),_material(Color("aaa48e")),0,false)
	_terrain_patch(PackedVector3Array([Vector3(-11.25,3.12,42.22),Vector3(11.25,3.12,42.22),Vector3(11.25,3.42,50.18),Vector3(-11.25,3.42,50.18)]),0.12,roof).name = "LowGreenRoof"
	_beam(Vector3(-11.24,3.05,42.18),Vector3(11.24,3.05,42.18),0.075,roof)
	for x in range(-11,12):
		_beam(Vector3(x,3.135,42.23),Vector3(x,3.435,50.17),0.013,roof)
	# Red fire cabinet stands on legs to the left of the recessed doorway.
	var red := _material(Color("9e2930"),0.7)
	_box(Vector3(3.9,-0.10,41.92),Vector3(1.65,1.28,0.46),red).name = "RedFireCabinet"
	for x in [4.61,3.19]:
		_box(Vector3(x,-0.74,41.92),Vector3(0.10,0.27,0.40),red)
	for x in [4.28,3.52]:
		_box(Vector3(x,-0.02,41.676),Vector3(0.66,0.92,0.025),_material(Color("442e2e")),0,false)
		for bar in range(7):
			_box(Vector3(x-0.28+bar*0.093,-0.02,41.653),Vector3(0.025,0.92,0.018),red,0,false)
		for y in [-0.45,-0.22,0.01,0.24,0.45]:
			_box(Vector3(x,y,41.649),Vector3(0.66,0.025,0.02),red,0,false)
	for x in [10.8,-5.4]:
		var foot := Vector3(x,-0.87,40.55)
		_beam(foot,foot+Vector3.UP*3.3,0.042,dark)
		_beam(foot+Vector3.UP*3.3,foot+Vector3(0.40,3.92,0),0.045,dark)
		_beam(foot+Vector3(0.40,3.92,0),foot+Vector3(0.18,4.30,0),0.09,dark)
	for node in get_children().slice(first): node.reparent(house,false)

func _make_rectangular_boundary() -> void:
	var boundary := Node3D.new()
	boundary.name = "RectangularBoundary"
	add_child(boundary)
	var first := get_child_count()
	var stone := _textured_material("stone",Color("aaa79b"),0.93)
	# The ladder-side wall is 10 metres beyond the previous curved boundary.
	# Rear clearance keeps the neighbouring block and team approach inside.
	_box(Vector3(40.8,0.45,3),Vector3(0.35,2.7,94),stone).name = "LadderSideWall"
	_box(Vector3(-48,0.45,3),Vector3(0.35,2.7,94),stone).name = "OppositeSideWall"
	_box(Vector3(-3.6,0.45,50),Vector3(89.15,2.7,0.35),stone).name = "RearWall"
	for x in [-48.0,40.8]:
		for z in range(-44,51,6):
			_box(Vector3(x,0.5,z),Vector3(0.52,2.8,0.52),stone)
	for x in range(-42,40,6):
		_box(Vector3(x,0.5,50),Vector3(0.52,2.8,0.52),stone)
	# Grille fence joins both side walls, with a pedestrian entrance at centre.
	for span in [Vector2(-48,-4),Vector2(4,40.8)]:
		var centre: float = (span.x+span.y)/2
		var width: float = span.y-span.x
		for y in [-0.62,1.1]:
			_box(Vector3(centre,y,-44),Vector3(width,0.07,0.08),metal)
		for i in range(int(ceil(width/0.25))+1):
			var x := lerpf(span.x,span.y,float(i)/ceil(width/0.25))
			_box(Vector3(x,0.25,-44),Vector3(0.035,2.3,0.035),dark)
		for i in range(int(ceil(width/3))+1):
			var x := lerpf(span.x,span.y,float(i)/ceil(width/3))
			_box(Vector3(x,0.3,-44),Vector3(0.14,2.4,0.14),metal)
	for node in get_children().slice(first): node.reparent(boundary,false)
	var road := Node3D.new()
	road.name = "FrontPublicRoad"
	add_child(road)
	first = get_child_count()
	var asphalt := _textured_material("stone",Color("414448"),0.98)
	var paint := _material(Color("e1dfcd"),1.0)
	_box(Vector3(0,-0.98,-52),Vector3(160,0.2,9),asphalt).name = "TwoWayAsphalt"
	for z in [-46.2,-57.8]:
		_box(Vector3(0,-0.87,z),Vector3(160,0.1,2.6),campus_stone)
	for z in [-47.75,-56.25]:
		_box(Vector3(0,-0.873,z),Vector3(160,0.012,0.10),paint,0,false)
	for x in range(-77,80,6):
		_box(Vector3(x,-0.873,-52),Vector3(3,0.012,0.12),paint,0,false)
	for node in get_children().slice(first): node.reparent(road,false)


func _make_left_facade_lane() -> void:
	var lane := Node3D.new()
	lane.name = "LeftFacadeLane"
	add_child(lane)
	var first := get_child_count()
	var road := _textured_material("stone",Color("55575a"),0.98)
	var lawn := _textured_material("grass",Color("637544"),1.0)
	for i in range(44):
		var a := -1.2+float(i)/20
		var b := -1.2+float(i+1)/20
		var road_points := PackedVector3Array()
		for polar in [Vector2(24.4,a),Vector2(30.5,a),Vector2(30.5,b),Vector2(24.4,b)]:
			var point := _polar(polar.x,polar.y,0)
			point.y = side_lane_corner_height(point.z,polar.y)
			road_points.append(point)
		_terrain_patch(road_points,0.2,road).name = "SlopingLane_%d" % i
		var grass_points := PackedVector3Array()
		for polar in [Vector2(23.0,a),Vector2(24.3,a),Vector2(24.3,b),Vector2(23.0,b)]:
			var point := _polar(polar.x,polar.y,-0.82)
			if polar.x>24: point.y = side_lane_corner_height(point.z,polar.y)+0.05
			grass_points.append(point)
		_terrain_patch(grass_points,0.13,lawn).name = "SmallLawn_%d" % i
		var curb_points := PackedVector3Array()
		for polar in [Vector2(24.3,a),Vector2(24.45,a),Vector2(24.45,b),Vector2(24.3,b)]:
			var point := _polar(polar.x,polar.y,0)
			point.y = side_lane_corner_height(point.z,polar.y)+0.11
			curb_points.append(point)
		_terrain_patch(curb_points,0.18,paving)
	for angle in [-0.7,0.65]:
		var point := _polar(29.9,angle,0)
		point.y = side_lane_corner_height(point.z,angle)
		_beam(point,point+Vector3(0,5.5,0),0.045,dark)
		_box(point+Vector3(0,5.5,0),Vector3(0.6,0.1,0.20),glow,0,false)
	for angle in [-0.85,-0.5,0.4,0.8]:
		_shrub(_polar(23.45,angle,-0.62))
	# Fine blades and varied green shades break up the otherwise flat lawn texture.
	var blades := MultiMesh.new()
	blades.transform_format = MultiMesh.TRANSFORM_3D
	blades.use_colors = true
	var blade := SurfaceTool.new()
	blade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in [Vector3(-0.023,-0.06,0),Vector3(0.023,-0.06,0),Vector3(0,0.10,0)]:
		blade.set_normal(Vector3.FORWARD)
		blade.add_vertex(vertex)
	blades.mesh = blade.commit()
	blades.instance_count = 6000
	var rng := RandomNumberGenerator.new()
	rng.seed = 1717
	for i in range(blades.instance_count):
		var radius := rng.randf_range(23.08,24.22)
		var point := _polar(radius,rng.randf_range(-0.98,0.98),0)
		point.y = lerpf(-0.82,side_lane_height(point.z)+0.05,(radius-23.0)/1.3)+0.06
		var basis := Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(1,rng.randf_range(0.65,1.3),1))
		blades.set_instance_transform(i,Transform3D(basis,point))
		blades.set_instance_color(i,Color("57753b")*rng.randf_range(0.7,1.15))
	var grass_mesh := MultiMeshInstance3D.new()
	grass_mesh.multimesh = blades
	var blade_mat := _material(Color.WHITE,1.0)
	blade_mat.vertex_color_use_as_albedo = true
	blade_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass_mesh.material_override = blade_mat
	add_child(grass_mesh)
	for node in get_children().slice(first): node.reparent(lane,false)

func _tree(origin: Vector3,seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var bark := _textured_material("bark",Color("514b3e"),1.0)
	var height := rng.randf_range(6.8,9.6)
	var top := origin+Vector3(0.3,height*0.75,0.1)
	_tapered_branch(origin,top,0.30,0.085,bark)
	var foliage := MultiMesh.new()
	foliage.transform_format = MultiMesh.TRANSFORM_3D
	foliage.use_colors = true
	var leaf := SurfaceTool.new()
	leaf.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0,1.0]:
		for points in [[Vector3(0,0,-1),Vector3(side*0.5,0.12,-0.25),Vector3(0,0,0)], [Vector3(0,0,0),Vector3(side*0.5,0.12,-0.25),Vector3(side*0.4,0.1,0.4)], [Vector3(0,0,0),Vector3(side*0.4,0.1,0.4),Vector3(0,0,1)]]:
			for point in points: leaf.add_vertex(point)
	leaf.generate_normals()
	foliage.mesh = leaf.commit()
	foliage.instance_count = 3600
	var leaf_mat := _material(Color.WHITE,0.95)
	leaf_mat.vertex_color_use_as_albedo = true
	leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var index := 0
	for branch in range(15):
		var a := branch*2.399
		var start := origin+Vector3(0.1,height*(0.3+branch*0.025),0)
		var end := origin+Vector3(cos(a)*rng.randf_range(1.5,3.1),height*rng.randf_range(0.65,1.0),sin(a)*rng.randf_range(1.5,3.1))
		_tapered_branch(start,end,0.10,0.018,bark)
		for twig in range(4):
			var tip := end+Vector3(rng.randf_range(-0.9,0.9),rng.randf_range(-0.1,1.0),rng.randf_range(-0.9,0.9))
			_tapered_branch(end,tip,0.025,0.004,bark)
			for cluster in range(60):
				var pos := tip+Vector3(rng.randf_range(-1.1,1.1),rng.randf_range(-0.9,1.1),rng.randf_range(-1.1,1.1))
				var basis := Basis.from_euler(Vector3(rng.randf()*PI,rng.randf()*TAU,rng.randf()*PI)).scaled(Vector3(0.22,0.22,0.22)*rng.randf_range(0.7,1.7))
				foliage.set_instance_transform(index,Transform3D(basis,pos-origin))
				var tone := rng.randf_range(0.7,1.18)
				foliage.set_instance_color(index,Color(0.20*tone,0.29*tone,0.095*tone))
				index += 1
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = foliage
	instance.material_override = leaf_mat
	instance.position = origin
	add_child(instance)
	# Only the trunk blocks actors; foliage is visual, so bots do not navigate leaf triangles.
	_box(origin+Vector3(0,1.3,0),Vector3(0.45,2.6,0.45),bark).visible = false

func _tapered_branch(a: Vector3,b: Vector3,bottom: float,top: float,mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 10
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = (a+b)/2
	instance.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	add_child(instance)

func _shrub(origin: Vector3) -> void:
	var mat := _material(Color("455438"))
	for i in range(12):
		var a := i*2.399
		var leaf := _sphere(origin+Vector3(cos(a)*0.35,0.2+sin(i*4.1)*0.1,sin(a)*0.3),0.25,mat)
		leaf.scale = Vector3(1,0.65,1)
func _make_materials() -> void:
	marble = _textured_material("marble", Color("b9bbb6"), 0.32)
	wood = _textured_material("wood", Color("bc9368"), 0.75)
	door_wood = _textured_material("wood", Color("704323"), 0.52)
	paving = _textured_material("paving", Color("858b90"), 0.9)
	cream = _material(Color("c9c1ae"))
	dark = _material(Color("252c35"))
	metal = _material(Color("acb4b9"), 0.3)
	metal.metallic = 0.65
	glass = _material(Color(0.07, 0.12, 0.19, 0.82), 0.2)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow = _material(Color("fff4d9"))
	glow.emission_enabled = true
	glow.emission = Color("fff2d2")
	glow.emission_energy_multiplier = 1.7


func _material(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var key := str(color)+":"+str(roughness)
	if material_cache.has(key): return material_cache[key]
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	material_cache[key] = result
	return result


func _textured_material(kind: String, tint: Color, roughness: float) -> StandardMaterial3D:
	var image := Image.create(256, 256, false, Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 0.04
	for y in range(256):
		for x in range(256):
			var grain := noise.get_noise_2d(float(x), float(y))
			var shade := 1.0
			if kind == "wood":
				shade += 0.025 * sin(float(x) * 0.7 + grain * 4.0) + grain * 0.07
			elif kind == "bark":
				shade += grain*0.4 + sin(x*0.45+grain*6)*0.16
			elif kind in ["stone", "grass"]:
				shade += grain*0.09
			elif kind == "campus_tiles":
				var row := y/16
				var shifted := x+(16 if row%2==0 else 0)
				var tile := shifted/32
				shade = 0.55+fmod(absf(sin(float(tile*13+row*31))*43758.5453),1.0)*0.65+grain*0.07
				if shifted%32<1 or y%16<1: shade = 0.48
			elif kind == "marble":
				shade += grain * 0.1
				shade -= pow(abs(sin(float(x + y) * 0.025 + grain * 2.0)), 18.0) * 0.1
				if x < 2 or y < 2:
					shade = 0.69
			else:
				shade += grain * 0.13
				if x % 64 < 2 or (y + (32 if (x / 64) % 2 == 0 else 0)) % 64 < 2:
					shade = 0.64
			image.set_pixel(x, y, Color(tint.r * shade, tint.g * shade, tint.b * shade))
	image.generate_mipmaps()
	var result := StandardMaterial3D.new()
	result.roughness = roughness
	result.albedo_texture = ImageTexture.create_from_image(image)
	result.uv1_scale = Vector3(1.2, 1.2, 1.2) if kind != "wood" else Vector3(2.0, 0.6, 2.0)
	if kind == "campus_tiles": result.uv1_scale = Vector3(0.35,0.35,0.35)
	result.uv1_triplanar = true
	result.uv1_world_triplanar = true
	result.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return result


func _make_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("618bb5")
	sky_material.sky_horizon_color = Color("d1e1e9")
	sky_material.ground_horizon_color = Color("c2ced0")
	sky_material.ground_bottom_color = Color("84929a")
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e4e6ee")
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment_node.environment = environment
	add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-44, -145, 0)
	sun.light_color = Color("fff2d9")
	sun.light_energy = 0.42
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 85.0
	add_child(sun)



func _setup_navigation() -> void:
	navigation_region = NavigationRegion3D.new()
	navigation_region.name = "CampusNavigation"
	add_child(navigation_region)
	if not force_bake and ResourceLoader.exists("res://maps/campus_navigation.tres"):
		navigation_region.navigation_mesh = load("res://maps/campus_navigation.tres")
		_finish_navigation()
		return
	var nav := NavigationMesh.new()
	nav.agent_height = 1.8
	nav.agent_radius = 0.3
	nav.agent_max_climb = 0.4
	nav.cell_size = 0.1
	nav.cell_height = 0.1
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav, source, self)
	NavigationServer3D.bake_from_source_geometry_data_async(nav, source, func():
		navigation_region.navigation_mesh = nav
		_finish_navigation())


func _finish_navigation() -> void:
	var map_rid := get_world_3d().navigation_map
	# Physics catch-up can emit many physics frames in one idle frame after
	# scene construction. Wait for actual idle/server synchronization as well.
	for frame in range(3):
		await get_tree().physics_frame
		await get_tree().process_frame
	NavigationServer3D.map_force_update(map_rid)
	while NavigationServer3D.map_get_regions(map_rid).is_empty() or NavigationServer3D.map_get_iteration_id(map_rid)==0 or NavigationServer3D.region_get_iteration_id(navigation_region.get_rid())==0:
		await get_tree().physics_frame
		await get_tree().process_frame
		NavigationServer3D.map_force_update(map_rid)
	# A nonzero server iteration can precede the first usable query after mesh loading.
	while not NavigationServer3D.map_get_closest_point_owner(map_rid,Vector3(0,GROUND_FLOOR,0)).is_valid():
		await get_tree().physics_frame
		await get_tree().process_frame
		NavigationServer3D.map_force_update(map_rid)
	# Drain deferred region synchronization before exposing readiness to actors.
	for frame in range(3): await get_tree().process_frame
	NavigationServer3D.map_force_update(map_rid)
	navigation_ready = true


func _polar(radius: float, angle: float, height: float) -> Vector3:
	return Vector3(cos(angle) * radius, height, sin(angle) * radius)


func _box(position_value: Vector3, size: Vector3, material: Material, yaw: float = 0.0, solid: bool = true) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.position = position_value
	node.rotation.y = yaw
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	node.add_child(instance)
	if material is BaseMaterial3D and material.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if solid:
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		node.add_child(collision)
	add_child(node)
	return node


func _beam(a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = (a + b) / 2.0
	instance.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	add_child(instance)


func _cylinder(position_value: Vector3, radius: float, height: float, material: Material,segments: int=48) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position_value
	add_child(instance)


func _sphere(position_value: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position_value
	add_child(instance)
	return instance


func _label(text_value: String, position_value: Vector3, yaw: float, pixel_size: float) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.position = position_value
	label.rotation.y = yaw
	label.font_size = 42
	label.pixel_size = pixel_size
	label.modulate = Color("ede7d8")
	label.outline_size = 0
	label.double_sided = false
	add_child(label)
	return label


func _wedge(inner: float, outer: float, a: float, b: float, top: float, thickness: float, material: Material, solid: bool) -> void:
	if solid and (inner == ROOM_RADIUS or inner in [20.0,20.5]):
		var polygon := PackedVector2Array()
		for point in [_polar(inner,a,0),_polar(outer,a,0),_polar(outer,b,0),_polar(inner,b,0)]:
			polygon.append(Vector2(point.x,point.z))
		var openings: Array[PackedVector2Array] = []
		if top>0:
			openings.append(PackedVector2Array([Vector2(LIFT_CENTER.x-1.35,14.85),Vector2(LIFT_CENTER.x+1.35,14.85),Vector2(LIFT_CENTER.x+1.35,17.55),Vector2(LIFT_CENTER.x-1.35,17.55)]))
			for side in [-1.0,1.0]:
				var cut := PackedVector2Array()
				for point in [Vector2(-1.9,13.5),Vector2(1.9,13.5),Vector2(1.9,18.9),Vector2(-1.9,18.9)]:
					var p := stair_point(side,point.x,point.y,0)
					cut.append(Vector2(p.x,p.z))
				openings.append(cut)
		elif inner in [20.0,20.5]:
			openings.append(PackedVector2Array([Vector2(-7.72,-33),Vector2(-2.1,-33),Vector2(-2.1,-20.6),Vector2(-7.72,-20.6)]))
			# Clear the reference's sunken passage beside the front-left stair.
			openings.append(PackedVector2Array([Vector2(2.1,-32),Vector2(7.55,-32),Vector2(7.55,-20.6),Vector2(2.1,-20.6)]))
			openings.append(PackedVector2Array([Vector2(-4.9,-24.85),Vector2(4.9,-24.85),Vector2(4.9,-19.4),Vector2(-4.9,-19.4)]))
			openings.append(PackedVector2Array([Vector2(-2.1,19.4),Vector2(2.1,19.4),Vector2(2.1,24.6),Vector2(-2.1,24.6)]))
		var pieces: Array[PackedVector2Array] = [polygon]
		for opening in openings:
			var clipped: Array[PackedVector2Array] = []
			for piece in pieces: clipped.append_array(Geometry2D.clip_polygons(piece,opening))
			pieces = clipped
		for piece in pieces:
			var indices := Geometry2D.triangulate_polygon(piece)
			for index in range(0,indices.size(),3):
				var points := PackedVector3Array()
				for corner in range(3):
					var p: Vector2 = piece[indices[index+corner]]
					points.append(Vector3(p.x,top,p.y))
				for corner in range(3): points.append(points[corner]-Vector3.UP*thickness)
				var mesh := SurfaceTool.new()
				mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
				_quad(mesh,points[0],points[2],points[1],points[0])
				_quad(mesh,points[3],points[4],points[5],points[3])
				for corner in range(3): _quad(mesh,points[corner],points[(corner+1)%3],points[(corner+1)%3+3],points[corner+3])
				var instance := MeshInstance3D.new()
				instance.mesh = mesh.commit()
				instance.material_override = material
				add_child(instance)
				var body := StaticBody3D.new()
				var shape := ConvexPolygonShape3D.new()
				shape.points = points
				var collision := CollisionShape3D.new()
				collision.shape = shape
				body.add_child(collision)
				add_child(body)
		return
	var points := PackedVector3Array([
		_polar(inner, a, top), _polar(outer, a, top), _polar(outer, b, top), _polar(inner, b, top),
		_polar(inner, a, top - thickness), _polar(outer, a, top - thickness),
		_polar(outer, b, top - thickness), _polar(inner, b, top - thickness)])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(surface, points[0], points[3], points[2], points[1])
	_quad(surface, points[4], points[5], points[6], points[7])
	for index in range(4):
		var next := (index + 1) % 4
		_quad(surface, points[index], points[next], points[next + 4], points[index + 4])
	if inner > 0.0:
		var instance := MeshInstance3D.new()
		instance.mesh = surface.commit()
		instance.material_override = material
		add_child(instance)
	if solid:
		var body := StaticBody3D.new()
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		add_child(body)


func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.length_squared() < 0.5:
		normal = (c - a).cross(d - a).normalized()
	for point in [a, c, b, a, d, c]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(point.x, point.z))
		surface.add_vertex(point)

func _make_lobby_fixtures() -> void:
	var first := get_child_count()
	for z in [-2.0,-0.8,0.4]:
		var origin := Vector3(-9.5,0,z)
		_cylinder(origin+Vector3(0,0.07,0),0.25,0.14,dark)
		_beam(origin,origin+Vector3(0,2.7,0),0.02,metal)
		for stripe in range(3):
			var colors := [Color("3b9ac0"),Color("eee9dd"),Color("438765")]
			_box(origin+Vector3(0.38,2.35-stripe*0.19,0),Vector3(0.75,0.18,0.02),_material(colors[stripe]),0,false)
	_box(Vector3(-9.1,1.5,3.2),Vector3(0.09,1.1,1.9),dark)
	_box(Vector3(-9.1,0.55,3.2),Vector3(0.09,1.1,0.09),metal,0,false)
	for x in [-1.7,1.7]:
		_cylinder(Vector3(x,0.26,18.2),0.24,0.52,cream)
		_shrub(Vector3(x,0.65,18.2))
	for node in get_children().slice(first): node.position.y += GROUND_FLOOR

func _batch_static_visuals() -> void:
	# Preserve collision bodies and movable lift parts. Merge static render surfaces
	# by material to avoid thousands of draw calls from the cornices/panels/rails.
	var groups: Dictionary = {}
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node == lift or node.is_queued_for_deletion(): continue
		for child in node.get_children(): stack.append(child)
		if not node is MeshInstance3D or node.is_queued_for_deletion(): continue
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null or not mesh_node.is_visible_in_tree(): continue
		var mat := mesh_node.material_override
		if mat == null: continue
		var key := str(mat.get_instance_id())+":"+str(mesh_node.cast_shadow)
		if not groups.has(key):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = {"surface":surface,"material":mat,"shadow":mesh_node.cast_shadow}
		var surface: SurfaceTool = groups[key]["surface"]
		var source_mesh: Mesh = mesh_node.mesh
		var arrays := source_mesh.surface_get_arrays(0)
		if arrays[Mesh.ARRAY_INDEX] == null or arrays[Mesh.ARRAY_INDEX].is_empty():
			var indexed := SurfaceTool.new()
			indexed.create_from(source_mesh,0)
			indexed.index()
			source_mesh = indexed.commit()
		surface.append_from(source_mesh,0,global_transform.affine_inverse()*mesh_node.global_transform)
		mesh_node.queue_free()
	for key in groups:
		var mesh := MeshInstance3D.new()
		mesh.name = "StaticVisualBatch"
		mesh.mesh = groups[key]["surface"].commit()
		mesh.material_override = groups[key]["material"]
		mesh.cast_shadow = groups[key]["shadow"]
		add_child(mesh)
