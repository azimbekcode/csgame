extends Node3D
## Four-level circular reconstruction from the user's front-elevation photograph.
## Interior dimensions are estimates pending the original reference videos.
const SEGMENTS := 96
const INNER_RADIUS := 6.5
const OUTER_RADIUS := 20.0
const FLOOR_HEIGHT := 4.0
const FLOOR_COUNT := 4
const ROOM_RADIUS := 11.0
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
var paving: StandardMaterial3D
var glow: StandardMaterial3D
var limestone: StandardMaterial3D
var bronze: StandardMaterial3D
var navigation_ready := false
var force_bake := false
var navigation_region: NavigationRegion3D
var room_entries: Array[Vector3] = []
var lift: Node3D
var material_cache: Dictionary = {}

func _ready() -> void:
	_make_materials()
	limestone = _textured_material("stone", Color("e2d8bd"), 0.87)
	bronze = _material(Color("55402c"), 0.42)
	_make_environment()
	_make_floors()
	_make_facade()
	_make_rooms()
	_make_stairs()
	_make_entrances()
	_make_dome()
	_make_lift()
	_make_campus()
	_make_lobby_fixtures()
	_batch_static_visuals()
	call_deferred("_setup_navigation")

func _make_floors() -> void:
	_cylinder(Vector3(0,-0.15,0), OUTER_RADIUS, 0.3, marble)
	for level in range(FLOOR_COUNT):
		var h := level * FLOOR_HEIGHT
		for segment in range(SEGMENTS):
			var a := TAU * segment / SEGMENTS
			var b := TAU * (segment+1) / SEGMENTS
			_wedge(0.0 if level == 0 else INNER_RADIUS, ROOM_RADIUS, a,b,h,0.28,marble,true)
			var stair_opening := cos((a+b)/2.0) > cos(deg_to_rad(25.0))
			var lift_opening := false
			if level == 0 or (not stair_opening and not lift_opening):
				_wedge(ROOM_RADIUS,OUTER_RADIUS,a,b,h,0.28,marble,true)
			if level > 0:
				_make_balcony_rail(a,b,h)
				_wedge(INNER_RADIUS,ROOM_RADIUS,a,b,h-0.29,0.025,cream,false)
			if level == FLOOR_COUNT-1: _wedge(INNER_RADIUS,OUTER_RADIUS,a,b,ROOF_HEIGHT,0.23,cream,false)
		for light_index in range(16):
			var lamp := OmniLight3D.new()
			lamp.position = _polar(9.0,TAU*light_index/16.0,h+3.4)
			lamp.light_color = Color("fff0d8")
			lamp.light_energy = 0.22
			lamp.omni_range = 8
			add_child(lamp)
			_box(lamp.position+Vector3(0,0.28,0),Vector3(0.16,0.035,0.16),glow,0,false)
	_cylinder(Vector3(0,0.013,0),3.3,0.02,_material(Color("555b50")))
	_cylinder(Vector3(0,0.028,0),3.05,0.02,_material(Color("286251")))
	for i in range(24):
		var a := TAU*i/24
		_beam(_polar(1.0,a,0.05),_polar(2.5,a+0.18,0.05),0.03,metal)
	var emblem := _label("SAMARQAND DAVLAT\nUNIVERSITETI",Vector3(0,0.08,0),0,0.012)
	emblem.rotation.x = -PI/2
	for i in range(16):
		var a := TAU*i/16.0
		_beam(_polar(0.8,a,0.055),_polar(2.8,a,0.055),0.025,bronze)

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
			var opening := (front and level == 1) or (rear and level in [0,1])
			var win_width := 3.0 if bay%3==0 else 1.9
			var win_height := 2.5 if level < 2 else 6.4
			var mat: Material = plinth if level == 0 else limestone
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
		_box(_polar(radius,a,h),Vector3(2*radius*sin(PI/SEGMENTS)+0.02,height,0.24),mat,-a-PI/2,false)

func _window(origin: Vector3,yaw: float,width: float,height: float,arched: bool=false) -> void:
	var assembly := Node3D.new()
	assembly.position = origin
	assembly.rotation.y = yaw
	add_child(assembly)
	var pane_mat := _material(Color("243a43"),0.17)
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
		var h := level*4.0
		var height := 3.72
		for i in range(SEGMENTS):
			var a := TAU*(i+0.5)/SEGMENTS
			var degrees := rad_to_deg(a)
			var doorway := minf(degrees,360-degrees)<33 or absf(degrees-90)<10 or absf(degrees-270)<10
			for d in door_angles:
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
		for d in [67.5,112.5,157.5,202.5,247.5,292.5]:
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
			_make_lecture_room(_polar(13.2,a,h),PI/2-a)
			var lamp := OmniLight3D.new()
			lamp.position = _polar(15,a,h+3.2)
			lamp.omni_range = 7
			lamp.light_energy = 0.5
			lamp.light_color = Color("fff1d9")
			add_child(lamp)
		# Rear/front axial corridors stay inside the circular shell.
		for z in [-15.6,15.6]:
			for x in [-2.2,2.2]:
				_box(Vector3(x,h+1.9,z),Vector3(0.16,3.8,8.2),wood)

func _make_lecture_room(origin: Vector3,yaw: float) -> void:
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
	_box(Vector3(3.35,1.8,1.9),Vector3(0.06,1.15,2.9),dark,0,false)
	_box(Vector3(0,3.73,2.2),Vector3(6.5,0.08,6.3),cream,0,false)
	for x in [-2.1,2.1]:
		for z in [0.0,2.3,4.5]:
			_cylinder(Vector3(x,3.66,z),0.16,0.025,glow)
	_box(Vector3(0,3.62,2.2),Vector3(0.94,0.12,0.94),cream,0,false)
	_box(Vector3(0,3.55,2.2),Vector3(0.64,0.025,0.64),seats,0,false)
	for stripe in range(8):
		_box(Vector3(0,3.53,1.95+stripe*0.07),Vector3(0.59,0.015,0.025),metal,0,false)
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

func _make_stairs() -> void:
	# Two flights inside the east sector; no external rectangular stair tower.
	for level in range(FLOOR_COUNT):
		var h := level*4.0
		_box(Vector3(14.35,h-0.14,5.0),Vector3(7.4,0.28,2.0),marble)
		if level==FLOOR_COUNT-1: continue
		_box(Vector3(14.5,h+1.86,-5.0),Vector3(6.2,0.28,2.0),marble)
		_stair_flight(12.7,h,4,-4,2)
		_stair_flight(16.0,h+2,-4,4,2)
		for x in [11.6,13.8]: _beam(Vector3(x,h+1,4),Vector3(x,h+3,-4),0.035,metal)
		for x in [14.9,17.1]: _beam(Vector3(x,h+3,-4),Vector3(x,h+5,4),0.035,metal)
		_label("%d → %d  QAVAT" % [level,level+1],Vector3(14.3,h+2.6,5.3),0,0.005)

func _stair_flight(x: float,base: float,start_z: float,end_z: float,rise: float,width: float=2.2) -> void:
	var steps := int(ceil(rise/0.16))
	for step in range(steps):
		var top := rise*(step+1)/steps
		var z := lerpf(start_z,end_z,(step+0.5)/steps)
		_box(Vector3(x,base+top-0.06,z),Vector3(width,0.12,absf(end_z-start_z)/steps+0.01),marble,0,false)
	_stair_slab(x,width,base,start_z,end_z,rise)
	_ramp(x,width,base,start_z,end_z,rise)

func _stair_railing(a: Vector3,b: Vector3) -> void:
	_beam(a+Vector3.UP,b+Vector3.UP,0.035,metal)
	_beam(a+Vector3.UP*0.12,b+Vector3.UP*0.12,0.025,metal)
	var count := maxi(1,int(ceil(a.distance_to(b)/0.38)))
	for i in range(count+1):
		var foot := a.lerp(b,float(i)/count)
		_beam(foot+Vector3.UP*0.08,foot+Vector3.UP,0.018,dark)

func _stair_slab(x: float,width: float,base: float,start_z: float,end_z: float,rise: float) -> void:
	var points := PackedVector3Array([
		Vector3(x-width/2,base-0.06,start_z),Vector3(x+width/2,base-0.06,start_z),
		Vector3(x+width/2,base+rise-0.06,end_z),Vector3(x-width/2,base+rise-0.06,end_z)])
	for i in range(4): points.append(points[i]-Vector3.UP*0.20)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_quad(st,points[0],points[3],points[2],points[1])
	_quad(st,points[4],points[5],points[6],points[7])
	for i in range(4): _quad(st,points[i],points[(i+1)%4],points[(i+1)%4+4],points[i+4])
	var instance := MeshInstance3D.new()
	instance.mesh = st.commit()
	instance.material_override = paving
	add_child(instance)

func _ramp(x: float,width: float,base: float,start_z: float,end_z: float,rise: float) -> void:
	var points := PackedVector3Array()
	for side in [-1.0,1.0]:
		points.append(Vector3(x+side*width/2,base-0.15,start_z))
		points.append(Vector3(x+side*width/2,base,start_z))
		points.append(Vector3(x+side*width/2,base-0.15,end_z))
		points.append(Vector3(x+side*width/2,base+rise,end_z))
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var body := StaticBody3D.new()
	body.name = "WalkableRamp"
	body.add_child(collision)
	add_child(body)

func _make_entrances() -> void:
	# Broad front stair, on the centerline of the reference photograph.
	_box(Vector3(0,3.85,-21.5),Vector3(6.4,0.3,3.0),marble)
	_stair_flight(0,-0.9,-33.0,-23.0,4.9,6.4)
	for side in [-1.0,1.0]:
		_beam(Vector3(side*3.25,0.1,-33),Vector3(side*3.25,5,-23),0.045,metal)
		for i in range(9):
			var z := -32.5+i*1.1
			var h := -0.9+(z+33)*0.49
			_beam(Vector3(side*3.25,h,z),Vector3(side*3.25,h+1.0,z),0.025,metal)
	# Rear door is flush with the round wall; the long projecting porch is removed.
	_box(Vector3(0,-0.14,20.7),Vector3(4.2,0.28,2.4),marble)
	_stair_flight(0,-0.9,24.0,21.9,0.9,4.2)
	for side in [-1.0,1.0]:
		_box(Vector3(side*1.55,1.4,20.4),Vector3(0.08,2.8,1.0),bronze)
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
			_box(Vector3(-0.2+rib*0.1,0.025,z),Vector3(0.025,0.018,0.65),_material(Color("c9af62")),0,false)

func _make_dome() -> void:
	var roof_mat := _material(Color(0.16,0.38,0.64,0.88),0.22)
	roof_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	roof_mat.metallic = 0.5
	# Raised blue skylight silhouette remains visible from the front courtyard.
	for i in range(48):
		var a := TAU*i/48
		var b := TAU*(i+1)/48
		_box(_polar(DOME_RADIUS,(a+b)/2,(ROOF_HEIGHT+DOME_BASE)/2),Vector3(2*DOME_RADIUS*sin(PI/48),DOME_BASE-ROOF_HEIGHT,0.08),glass,-(a+b)/2-PI/2,false)
		_beam(_polar(DOME_RADIUS,a,ROOF_HEIGHT),_polar(DOME_RADIUS,a,DOME_BASE),0.055,bronze)
		for ring in range(8):
			var t0 := PI/2*ring/8
			var t1 := PI/2*(ring+1)/8
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
			if i%3==0: _beam(_polar(r0,a,y0+0.02),_polar(r1,a,y1+0.02),0.025,metal)
			if ring in [1,3,5]: _beam(_polar(r0,a,y0+0.02),_polar(r0,b,y0+0.02),0.02,metal)

func _make_lift() -> void:
	lift = Node3D.new()
	lift.set_script(preload("res://scripts/lift.gd"))
	lift.position = LIFT_CENTER
	lift.rotation.y = PI
	add_child(lift)
	# Facing inward from the rear (+Z), negative X is the visitor's left.
	for level in range(FLOOR_COUNT):
		var h := level*4.0
		_box(Vector3(-2.65,h-0.14,16.2),Vector3(1.0,0.28,2.5),marble)
	# Doorway in the rear corridor's left wall is carved by replacing its lift-facing piece.
	for node in get_children():
		if node is StaticBody3D and absf(node.position.x+2.2)<0.01 and absf(node.position.z-15.6)<0.01:
			var h: float = node.position.y-1.9
			node.queue_free()
			_box(Vector3(-2.2,h+1.9,12.55),Vector3(0.16,3.8,2.1),wood)
			_box(Vector3(-2.2,h+1.9,19.0),Vector3(0.16,3.8,1.4),wood)
			_box(Vector3(-2.2,h+3.35,16.2),Vector3(0.16,0.9,5.2),cream)

func _make_campus() -> void:
	var asphalt := _textured_material("stone",Color("53575a"),0.98)
	var grass := _textured_material("grass",Color("62694a"),1.0)
	_box(Vector3(0,-1.08,0),Vector3(128,0.36,128),asphalt)
	for i in range(SEGMENTS):
		_wedge(20.5,23.0,TAU*i/SEGMENTS,TAU*(i+1)/SEGMENTS,-0.86,0.09,paving,true)
	for side in [-1.0,1.0]:
		_box(Vector3(side*36,-0.88,0),Vector3(18,0.08,90),grass)
		_box(Vector3(side*13,-0.88,-40),Vector3(13,0.08,20),grass)
		for z in [-46.0,-31.0,-14.0,3.0,20.0,38.0,52.0]:
			_tree(Vector3(side*(31.0+fmod(absf(z),6.0)),-0.83,z),int(absf(z)*31+side*7))
		for z in [-37.0,-12.0,13.0,38.0]:
			_beam(Vector3(side*25,-0.9,z),Vector3(side*25,4.7,z),0.065,dark)
			_box(Vector3(side*25,4.7,z),Vector3(0.6,0.1,0.28),glow,0,false)
	for z in [-60.0,60.0]: _box(Vector3(0,0.2,z),Vector3(120,2.2,0.25),limestone)
	for x in [-60.0,60.0]: _box(Vector3(x,0.2,0),Vector3(0.25,2.2,120),limestone)
	# Low stone planters/benches replace floating-looking wooden cover cubes.
	for point in [Vector3(7,-0.9,35),Vector3(-7,-0.9,38),Vector3(25,-0.9,17),Vector3(-25,-0.9,-15)]:
		_box(point+Vector3(0,0.42,0),Vector3(2.6,0.84,1.1),limestone)
		for offset in [-0.8,0.0,0.8]: _shrub(point+Vector3(offset,0.85,0))

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
	nav.agent_radius = 0.4
	nav.agent_max_climb = 0.4
	nav.cell_size = 0.2
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
	while NavigationServer3D.map_get_regions(map_rid).is_empty() or NavigationServer3D.map_get_iteration_id(map_rid)==0:
		await get_tree().physics_frame
		await get_tree().process_frame
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


func _cylinder(position_value: Vector3, radius: float, height: float, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 48
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
	if solid and inner == ROOM_RADIUS and top > 0.0:
		var polygon := PackedVector2Array()
		for point in [_polar(inner,a,0),_polar(outer,a,0),_polar(outer,b,0),_polar(inner,b,0)]:
			polygon.append(Vector2(point.x,point.z))
		var hole := PackedVector2Array([Vector2(LIFT_CENTER.x-1.35,14.9),Vector2(LIFT_CENTER.x+1.35,14.9),Vector2(LIFT_CENTER.x+1.35,17.5),Vector2(LIFT_CENTER.x-1.35,17.5)])
		var pieces := Geometry2D.clip_polygons(polygon,hole)
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
