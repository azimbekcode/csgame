extends Node3D
## Original articulated tactical character with shaped anatomy and fabric materials.
const WEAPONS = preload("res://scripts/weapons.gd")
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var torso: Node3D
var weapon_node: Node3D
var phase := 0.0
var moving_amount := 0.0
var team := 0
var weapon := "pistol"
static var fabrics: Dictionary = {}

func _ready() -> void:
	_build()

func _fabric(team_value: int) -> StandardMaterial3D:
	if fabrics.has(team_value): return fabrics[team_value]
	var image := Image.create(128,128,false,Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 43+team_value
	noise.frequency = 0.095
	var colors := [Color("404d43"),Color("697062"),Color("303c34"),Color("8a8c73")] if team_value==0 else [Color("8a7e60"),Color("b0a17d"),Color("605e48"),Color("d0bea0")]
	for y in range(128):
		for x in range(128):
			var n := noise.get_noise_2d(x,y)
			var c: Color = colors[0 if n < -0.2 else (1 if n < 0.05 else (2 if n < 0.23 else 3))]
			c *= 0.95 if (x+y)%2==0 else 1.0
			image.set_pixel(x,y,c)
	image.generate_mipmaps()
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(image)
	mat.roughness = 0.96
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(3,3,3)
	fabrics[team_value] = mat
	return mat

func _build() -> void:
	var fabric := _fabric(team)
	var gear := WEAPONS.material(Color("384139") if team==0 else Color("766c53"))
	var rubber := WEAPONS.material(Color("252724"))
	var skin := WEAPONS.material(Color("ad876c"))
	var lens := WEAPONS.material(Color("1b2829"))
	lens.metallic = 0.6
	lens.roughness = 0.18
	# Pelvis, shoulders and tapered chest use continuous curved profiles.
	_shape(self,Vector3(0,0.94,0),Vector3(0.34,0.23,0.25),fabric)
	torso = Node3D.new()
	torso.position.y = 1.04
	add_child(torso)
	_profile(torso,[Vector3(0.16,0,0.12),Vector3(0.18,0.15,0.13),Vector3(0.235,0.35,0.145),Vector3(0.19,0.43,0.12)],fabric)
	_rounded_box(torso,Vector3(0,0.22,-0.14),Vector3(0.34,0.35,0.10),gear)
	_rounded_box(torso,Vector3(0,0.20,0.15),Vector3(0.29,0.33,0.10),gear)
	# MOLLE stitching, four magazine pouches, belt and shoulder straps.
	for y in [0.09,0.16,0.23]:
		WEAPONS.box(torso,Vector3(0,y,-0.18),Vector3(0.32,0.018,0.013),gear)
	for x in [-0.12,-0.04,0.04,0.12]:
		_rounded_box(torso,Vector3(x,0.05,-0.20),Vector3(0.07,0.16,0.065),gear)
	for side in [-1.0,1.0]:
		_limb(torso,Vector3(side*0.13,0.16,0.09),Vector3(side*0.15,0.40,-0.11),0.038,gear)
		_shape(self,Vector3(side*0.18,0.96,0.03),Vector3(0.10,0.17,0.12),gear)
	_limb(torso,Vector3(0,0.39,0),Vector3(0,0.50,0),0.065,skin)
	# Human head proportions, ears, brow, nose, jaw, goggles and helmet rim.
	_shape(torso,Vector3(0,0.59,-0.005),Vector3(0.225,0.29,0.22),skin)
	_shape(torso,Vector3(0,0.53,-0.035),Vector3(0.18,0.13,0.19),skin)
	_shape(torso,Vector3(0,0.60,-0.123),Vector3(0.043,0.073,0.052),skin)
	for side in [-1.0,1.0]:
		_shape(torso,Vector3(side*0.115,0.595,0.01),Vector3(0.034,0.07,0.043),skin)
		_shape(torso,Vector3(side*0.058,0.63,-0.113),Vector3(0.094,0.047,0.043),rubber)
		_shape(torso,Vector3(side*0.058,0.632,-0.135),Vector3(0.077,0.028,0.012),lens)
		_limb(torso,Vector3(side*0.105,0.64,0.04),Vector3(side*0.065,0.48,-0.06),0.012,gear)
	_shape(torso,Vector3(0,0.705,0.012),Vector3(0.275,0.20,0.29),fabric)
	_shape(torso,Vector3(0,0.66,0),Vector3(0.288,0.035,0.30),gear)
	WEAPONS.box(torso,Vector3(0,0.73,-0.139),Vector3(0.044,0.05,0.019),rubber)
	# Jointed legs: the thigh and calf rotate independently while walking.
	for side in [-1.0,1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(side*0.12,0.94,0)
		add_child(hip)
		hips.append(hip)
		_limb(hip,Vector3.ZERO,Vector3(0,-0.40,0),0.108,fabric)
		_shape(hip,Vector3(side*0.06,-0.19,0.025),Vector3(0.12,0.18,0.13),fabric)
		var knee := Node3D.new()
		knee.position.y = -0.4
		hip.add_child(knee)
		knees.append(knee)
		_limb(knee,Vector3.ZERO,Vector3(0,-0.36,0.015),0.083,fabric)
		_shape(knee,Vector3(0,-0.025,-0.075),Vector3(0.15,0.17,0.07),rubber)
		_rounded_box(knee,Vector3(0,-0.39,-0.055),Vector3(0.17,0.17,0.29),rubber)
		for y in [-0.31,-0.345,-0.38]:
			WEAPONS.box(knee,Vector3(0,y,-0.126),Vector3(0.12,0.012,0.01),gear)
	# Bent elbows and hands meet the rifle's grip and handguard.
	for side in [-1.0,1.0]:
		var shoulder := Vector3(side*0.23,0.32,0)
		var elbow := Vector3(side*0.29,0.02,-0.13)
		var hand := Vector3(0.10 if side>0 else 0.04,0.16,-0.31 if side>0 else -0.55)
		_limb(torso,shoulder,elbow,0.078,fabric)
		_limb(torso,elbow,hand,0.065,fabric)
		_shape(torso,hand,Vector3(0.095,0.10,0.105),rubber)
		_shape(torso,shoulder,Vector3(0.17,0.18,0.18),fabric)
	# Readable team armband, rather than changing skin/anatomy between sides.
	_shape(torso,Vector3(-0.257,0.27,-0.005),Vector3(0.025,0.065,0.17),WEAPONS.material(Color("426a94") if team==0 else Color("b3934d")))
	weapon_node = WEAPONS.make_model(weapon)
	weapon_node.position = Vector3(0.1,0.20,-0.30)
	torso.add_child(weapon_node)

func animate(delta: float,speed_value: float,reloading: bool) -> void:
	moving_amount = move_toward(moving_amount,clampf(speed_value/3.9,0,1),delta*5)
	phase += delta*(5+speed_value*1.5)
	for i in range(hips.size()):
		var stride := sin(phase+i*PI)
		hips[i].rotation.x = stride*0.52*moving_amount
		knees[i].rotation.x = maxf(0,-stride)*0.7*moving_amount
	torso.position.y = 1.04+absf(sin(phase))*0.024*moving_amount
	torso.rotation.z = sin(phase)*0.025*moving_amount
	torso.rotation.x = -0.04*moving_amount
	weapon_node.rotation.z = -0.3 if reloading else 0.0

func _shape(parent: Node3D,pos: Vector3,size: Vector3,mat: Material) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1
	sphere.radial_segments = 20
	sphere.rings = 10
	var instance := MeshInstance3D.new()
	instance.mesh = sphere
	instance.position = pos
	instance.scale = size
	instance.material_override = mat
	parent.add_child(instance)

func _limb(parent: Node3D,a: Vector3,b: Vector3,radius: float,mat: Material) -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = a.distance_to(b)+radius
	capsule.radial_segments = 16
	capsule.rings = 8
	var instance := MeshInstance3D.new()
	instance.mesh = capsule
	instance.position = (a+b)/2
	instance.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	instance.material_override = mat
	parent.add_child(instance)

func _profile(parent: Node3D,rings: Array,mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(rings.size()-1):
		var lo: Vector3 = rings[ring]
		var hi: Vector3 = rings[ring+1]
		for i in range(24):
			var a := TAU*i/24
			var b := TAU*(i+1)/24
			var p := [Vector3(cos(a)*lo.x,lo.y,sin(a)*lo.z),Vector3(cos(b)*lo.x,lo.y,sin(b)*lo.z),Vector3(cos(b)*hi.x,hi.y,sin(b)*hi.z),Vector3(cos(a)*hi.x,hi.y,sin(a)*hi.z)]
			for j in [0,2,1,0,3,2]:
				st.set_uv(Vector2(float(i)/24,float(ring)/rings.size()))
				st.add_vertex(p[j])
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = mat
	parent.add_child(mesh)

func _rounded_box(parent: Node3D,pos: Vector3,size: Vector3,mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outline := [Vector2(-0.35,-0.5),Vector2(0.35,-0.5),Vector2(0.5,-0.35),Vector2(0.5,0.35),Vector2(0.35,0.5),Vector2(-0.35,0.5),Vector2(-0.5,0.35),Vector2(-0.5,-0.35)]
	for level in range(3):
		var heights := [-0.5,-0.37,0.37,0.5]
		var scales := [0.8,1.0,1.0,0.8]
		for i in range(8):
			var a: Vector2 = outline[i]
			var b: Vector2 = outline[(i+1)%8]
			var p := [Vector3(a.x*size.x*scales[level],heights[level]*size.y,a.y*size.z*scales[level]),Vector3(b.x*size.x*scales[level],heights[level]*size.y,b.y*size.z*scales[level]),Vector3(b.x*size.x*scales[level+1],heights[level+1]*size.y,b.y*size.z*scales[level+1]),Vector3(a.x*size.x*scales[level+1],heights[level+1]*size.y,a.y*size.z*scales[level+1])]
			for j in [0,1,2,0,2,3]: st.add_vertex(pos+p[j])
	for side in [-1.0,1.0]:
		for i in range(8):
			var a: Vector2 = outline[i]
			var b: Vector2 = outline[(i+1)%8]
			var points := [Vector3(0,side*size.y/2,0),Vector3(a.x*size.x*0.8,side*size.y/2,a.y*size.z*0.8),Vector3(b.x*size.x*0.8,side*size.y/2,b.y*size.z*0.8)]
			if side<0: points.reverse()
			for point in points: st.add_vertex(pos+point)
	st.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = st.commit()
	instance.material_override = mat
	parent.add_child(instance)
