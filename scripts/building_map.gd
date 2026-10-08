extends Node3D
## Approximate reconstruction of IMG_0038–IMG_0042. Units are metres.
## Dimensions and room orientations are estimates, not a measured survey.

const SEGMENTS := 32
const INNER_RADIUS := 8.5
const OUTER_RADIUS := 12.0
const FLOOR_HEIGHT := 4.0
const FLOOR_COUNT := 4

var marble: StandardMaterial3D
var wood: StandardMaterial3D
var cream: StandardMaterial3D
var dark: StandardMaterial3D
var metal: StandardMaterial3D
var glass: StandardMaterial3D
var paving: StandardMaterial3D
var glow: StandardMaterial3D
var navigation_ready := false
var force_bake := false
var navigation_region: NavigationRegion3D


func _ready() -> void:
	_make_materials()
	_make_environment()
	_make_atrium()
	_make_stairs()
	_make_lecture_room()
	_make_rear_entry()
	_make_lobby_details()
	_make_campus()
	call_deferred("_setup_navigation")


func _make_materials() -> void:
	marble = _textured_material("marble", Color("d5d6ce"), 0.32)
	wood = _textured_material("wood", Color("bc9368"), 0.75)
	paving = _textured_material("paving", Color("858b90"), 0.9)
	cream = _material(Color("eee7d7"))
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
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
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
	var result := _material(Color.WHITE, roughness)
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
	sky_material.ground_horizon_color = Color("d1d5ce")
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e4e6ee")
	environment.ambient_light_energy = 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.light_color = Color("fff2d9")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 85.0
	add_child(sun)


func _make_atrium() -> void:
	# A solid ground disc and three open-centre balcony rings.
	# One visible disc avoids per-object light seams between the collision wedges.
	_cylinder(Vector3(0, -0.14, 0), OUTER_RADIUS, 0.28, marble)
	for level in range(FLOOR_COUNT):
		var height := level * FLOOR_HEIGHT
		for segment in range(SEGMENTS):
			var a := TAU * segment / SEGMENTS
			var b := TAU * (segment + 1) / SEGMENTS
			_wedge(0.0 if level == 0 else INNER_RADIUS, OUTER_RADIUS, a, b, height, 0.28, marble, true)
			if level > 0:
				_wedge(INNER_RADIUS, OUTER_RADIUS, a, b, height - 0.29, 0.05, cream, false)
				_make_balcony_rail(a, b, height)
			var angle := (a + b) / 2.0
			var tangent_rotation := -angle - PI / 2.0
			var length := 2.0 * OUTER_RADIUS * sin(PI / SEGMENTS)
			var passage := segment in [0, 1, 30, 31]
			passage = passage or (level == 0 and segment in [7, 8])
			passage = passage or (level == 3 and segment in [15, 16])
			passage = passage or (level == 1 and segment in [23, 24])
			if passage:
				_box(_polar(OUTER_RADIUS, angle, height + 3.55), Vector3(length, 0.9, 0.28), wood, tangent_rotation)
			else:
				_box(_polar(OUTER_RADIUS, angle, height + 2.0), Vector3(length, 4.0, 0.28), wood, tangent_rotation)
				if segment in [4, 11, 20, 25]:
					_closed_door(_polar(OUTER_RADIUS - 0.23, angle, height), tangent_rotation + PI)
			# Thin black joints reproduce the panel grid seen in the videos.
			if not passage:
				_box(_polar(OUTER_RADIUS - 0.17, a, height + 2.0), Vector3(0.06, 4.0, 0.08), dark, -a, false)
			if not passage:
				for band in [1.3, 2.6]:
					_box(_polar(OUTER_RADIUS - 0.16, angle, height + band), Vector3(length, 0.022, 0.035), dark, tangent_rotation, false)
			if segment % 2 == 0:
				_box(_polar(10.2, angle, height + 3.69), Vector3(0.24, 0.05, 0.52), glow, -angle, false)
		for light_index in range(4):
			var lamp := OmniLight3D.new()
			lamp.position = _polar(9.5, TAU * light_index / 4.0 + 0.6, height + 3.35)
			lamp.light_color = Color("ffedcf")
			lamp.light_energy = 0.7
			lamp.omni_range = 10.0
			add_child(lamp)
		if level == 3:
			for segment in range(SEGMENTS):
				_wedge(INNER_RADIUS, OUTER_RADIUS, TAU * segment / SEGMENTS, TAU * (segment + 1) / SEGMENTS, 16.0, 0.18, cream, false)
	_make_dome()


func _make_balcony_rail(a: float, b: float, height: float) -> void:
	var mid := (a + b) / 2.0
	var length := 2.0 * INNER_RADIUS * sin((b - a) / 2.0)
	_box(_polar(INNER_RADIUS, mid, height + 0.56), Vector3(length, 0.88, 0.08), glass, -mid - PI / 2.0)
	_beam(_polar(INNER_RADIUS, a, height + 1.1), _polar(INNER_RADIUS, b, height + 1.1), 0.045, metal)
	_beam(_polar(INNER_RADIUS, a, height + 0.05), _polar(INNER_RADIUS, a, height + 1.12), 0.035, metal)
	_box(_polar(INNER_RADIUS, mid, height - 0.14), Vector3(length, 0.25, 0.12), dark, -mid - PI / 2.0, false)


func _make_dome() -> void:
	var roof_glass := _material(Color(0.72, 0.84, 0.9, 0.68), 0.22)
	roof_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	roof_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(6):
		var t0 := float(ring) / 6.0 * PI / 2.0
		var t1 := float(ring + 1) / 6.0 * PI / 2.0
		var r0 := OUTER_RADIUS * cos(t0)
		var r1 := OUTER_RADIUS * cos(t1)
		var y0 := 16.0 + 4.0 * sin(t0)
		var y1 := 16.0 + 4.0 * sin(t1)
		for segment in range(SEGMENTS):
			var a := TAU * segment / SEGMENTS
			var b := TAU * (segment + 1) / SEGMENTS
			_quad(surface, _polar(r0, a, y0), _polar(r0, b, y0), _polar(r1, b, y1), _polar(r1, a, y1))
			_beam(_polar(r0, a, y0), _polar(r1, a, y1), 0.042, dark)
			_beam(_polar(r0, a, y0), _polar(r0, b, y0), 0.032, dark)
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.material_override = roof_glass
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func _make_stairs() -> void:
	# Two flights per storey, with smooth ramps beneath the visible steps.
	for level in range(FLOOR_COUNT):
		var height := level * FLOOR_HEIGHT
		_box(Vector3(15.4, height - 0.14, 3.35), Vector3(8.8, 0.28, 1.9), marble)
		if level == FLOOR_COUNT - 1:
			continue
		_box(Vector3(16.2, height + 1.86, -3.35), Vector3(6.0, 0.28, 1.9), marble)
		_stair_flight(14.5, height, 2.4, -2.4, 2.0)
		_stair_flight(17.7, height + 2.0, -2.4, 2.4, 2.0)
		for x in [13.4, 15.6]:
			_beam(Vector3(x, height + 1.0, 2.4), Vector3(x, height + 3.0, -2.4), 0.045, metal)
		for x in [16.6, 18.8]:
			_beam(Vector3(x, height + 3.0, -2.4), Vector3(x, height + 5.0, 2.4), 0.045, metal)
		for z in [-4.22, 4.22]:
			_box(Vector3(16.2, height + 0.55 + (2.0 if z < 0 else 0.0), z), Vector3(6.0, 1.1, 0.09), glass)
		_label("ZINAPOYA / %d" % (level + 1), Vector3(12.1, height + 2.3, 3.1), PI / 2.0, 0.007)
	_box(Vector3(19.7, 8.0, 0), Vector3(0.25, 16.0, 9.0), wood)
	for z in [-4.5, 4.5]:
		_box(Vector3(16.0, 8.0, z), Vector3(7.5, 16.0, 0.25), cream)
	_box(Vector3(16.0, 16.0, 0), Vector3(7.5, 0.2, 9.0), cream)


func _stair_flight(x: float, base: float, start_z: float, end_z: float, rise: float) -> void:
	var steps := 12
	var tread: float = absf(end_z - start_z) / steps
	for step in range(steps):
		var top := rise * (step + 1) / steps
		var z := lerpf(start_z, end_z, (step + 0.5) / steps)
		_box(Vector3(x, base + top - 0.06, z), Vector3(2.2, 0.12, tread + 0.015), marble, 0.0, false)
	_ramp(x, 2.2, base, start_z, end_z, rise)


func _ramp(x: float, width: float, base: float, start_z: float, end_z: float, rise: float) -> void:
	var points := PackedVector3Array()
	for side in [-1.0, 1.0]:
		points.append(Vector3(x + side * width / 2.0, base - 0.15, start_z))
		points.append(Vector3(x + side * width / 2.0, base, start_z))
		points.append(Vector3(x + side * width / 2.0, base - 0.15, end_z))
		points.append(Vector3(x + side * width / 2.0, base + rise, end_z))
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var body := StaticBody3D.new()
	body.name = "WalkableRamp"
	body.add_child(collision)
	add_child(body)


func _make_lecture_room() -> void:
	var base := 12.0
	_box(Vector3(-20, base - 0.15, 0), Vector3(16.0, 0.3, 14.0), cream)
	for z in [-7.0, 7.0]:
		_box(Vector3(-20, base + 2.0, z), Vector3(16.0, 4.0, 0.25), wood)
	for z in [-4.1, 4.1]:
		_box(Vector3(-12.8, base + 2.0, z), Vector3(0.25, 4.0, 5.8), wood)
	_box(Vector3(-12.8, base + 3.55, 0), Vector3(0.25, 0.9, 2.4), wood)
	_box(Vector3(-28, base + 2.0, 0), Vector3(0.25, 4.0, 14.0), wood)
	_box(Vector3(-20, base + 4.0, 0), Vector3(16.0, 0.18, 14.0), cream)
	_label("AUDITORIYA", Vector3(-12.6, base + 2.8, 0), PI / 2.0, 0.008)
	for row in range(9):
		var x := -17.2 - row * 1.08
		var height := base + (row + 1) * 0.18
		_box(Vector3(x, height - 0.09, 0), Vector3(1.08, 0.18, 13.5), cream, 0.0, false)
		for side in [-1.0, 1.0]:
			var z: float = side * 3.65
			_box(Vector3(x + 0.18, height + 0.77, z), Vector3(0.62, 0.09, 4.75), wood)
			_box(Vector3(x + 0.44, height + 0.42, z), Vector3(0.08, 0.65, 4.75), dark)
			_box(Vector3(x - 0.32, height + 0.46, z), Vector3(0.35, 0.08, 4.6), wood)
			for offset in [-2.0, 2.0]:
				_box(Vector3(x - 0.25, height + 0.22, z + offset), Vector3(0.07, 0.45, 0.07), dark, 0.0, false)
	_ramp_lecture_floor()
	for z in [-3.6, 3.6]:
		_window(Vector3(-27.82, base + 2.55, z), PI / 2.0, 2.0, 1.65)
		for slat in range(6):
			_box(Vector3(-27.65, base + 3.2 + slat * 0.065, z), Vector3(0.05, 0.04, 2.1), dark, 0.0, false)
	_box(Vector3(-14.9, base + 0.62, 3.8), Vector3(0.65, 1.24, 0.95), wood)
	_box(Vector3(-14.9, base + 1.25, 3.8), Vector3(0.9, 0.08, 1.1), wood)
	_box(Vector3(-14.1, base + 1.6, -3.7), Vector3(0.09, 1.5, 2.7), dark)
	_box(Vector3(-14.1, base + 0.55, -3.7), Vector3(0.12, 1.1, 0.12), metal, 0.0, false)
	for x in [-16.0, -21.0, -25.5]:
		for z in [-4.0, 0.0, 4.0]:
			_box(Vector3(x, base + 3.85, z), Vector3(0.24, 0.05, 0.24), glow, 0.0, false)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(-21.0, base + 3.5, 0)
	lamp.omni_range = 12.0
	lamp.light_energy = 1.2
	add_child(lamp)


func _ramp_lecture_floor() -> void:
	var before := get_child_count()
	_ramp(0, 13.5, 12.0, 0, 9.72, 1.62)
	var ramp := get_child(before) as Node3D
	ramp.rotation.y = -PI / 2.0
	ramp.position.x = -16.66


func _make_rear_entry() -> void:
	_box(Vector3(0, -0.14, 18.5), Vector3(6.0, 0.28, 14.0), marble)
	for x in [-3.0, 3.0]:
		_box(Vector3(x, 2.0, 18.5), Vector3(0.25, 4.0, 14.0), wood)
		for z in range(13, 25, 2):
			_box(Vector3(x * 0.95, 2.0, z), Vector3(0.035, 4.0, 0.035), dark, 0.0, false)
	_box(Vector3(0, 4.0, 18.5), Vector3(6.0, 0.18, 14.0), cream)
	for z in [14.0, 18.0, 22.0]:
		_box(Vector3(0, 3.84, z), Vector3(0.23, 0.05, 0.23), glow, 0.0, false)
	var yellow := _material(Color("e8bb3d"))
	for z in range(15, 25):
		_box(Vector3(0, 0.012, z), Vector3(0.55, 0.02, 0.58), yellow, 0.0, false)
		for rib in range(5):
			_box(Vector3(-0.22 + rib * 0.11, 0.027, z), Vector3(0.02, 0.01, 0.52), yellow, 0.0, false)
	for x in range(7):
		for z in range(7):
			_sphere(Vector3(-0.3 + x * 0.1, 0.033, 24.0 + z * 0.1), 0.018, yellow)
	for x in [-2.12, 2.12]:
		_box(Vector3(x, 1.45, 25.0), Vector3(1.6, 2.9, 0.08), glass)
		for edge in [-0.8, 0.8]:
			_box(Vector3(x + edge, 1.5, 25), Vector3(0.08, 3.0, 0.1), dark)
	_box(Vector3(0, 3.0, 25), Vector3(6.0, 0.12, 0.14), dark)
	_box(Vector3(1.16, 1.42, 25.7), Vector3(0.08, 2.84, 1.4), glass)
	_box(Vector3(-1.16, 1.42, 25.7), Vector3(0.08, 2.84, 1.4), glass)
	_label("ORQA KIRISH", Vector3(0, 3.4, 24.84), PI, 0.008)
	_box(Vector3(0, -0.14, 27), Vector3(9.0, 0.28, 4.0), paving)
	for step in range(5):
		var top := -0.18 * (step + 1)
		_box(Vector3(0, top - 0.09, 29.2 + step * 0.4), Vector3(9.0, 0.18, 0.4), paving, 0.0, false)
	_ramp(0, 9.0, -0.9, 31.0, 29.0, 0.9)
	_box(Vector3(0, 4.1, 26.8), Vector3(10.0, 0.28, 4.6), cream)
	for x in [-3.8, 3.8]:
		_box(Vector3(x, 2.0, 27.4), Vector3(0.55, 4.0, 0.55), cream)
		for rib in range(6):
			_box(Vector3(x - 0.22 + rib * 0.088, 2.0, 27.7), Vector3(0.03, 3.85, 0.04), metal, 0.0, false)
		_beam(Vector3(x, 0.2, 27.6), Vector3(x, -0.65, 30.5), 0.045, metal)
	for z in [22.0, 24.0]:
		_plant(Vector3(2.4, 0, z))
	_make_rear_courtyard()


func _make_rear_courtyard() -> void:
	# Only the small area visible in IMG_0042 is represented for now.
	_box(Vector3(0, -1.05, 36.5), Vector3(30.0, 0.3, 15.0), paving)
	var grass := _material(Color("638447"))
	for x in [-10.0, 10.0]:
		_box(Vector3(x, -0.88, 36.0), Vector3(6.0, 0.06, 10.0), grass)
		for z in [33.0, 37.0, 40.0]:
			_plant(Vector3(x, -0.85, z), 1.65)
	_box(Vector3(1.8, -0.3, 50.3), Vector3(1.2, 1.2, 0.3), _material(Color("b83a32")))


func _make_lobby_details() -> void:
	var emblem := _material(Color("346760"), 0.5)
	_cylinder(Vector3(0, 0.012, 0), 3.0, 0.02, dark)
	_cylinder(Vector3(0, 0.026, 0), 2.65, 0.02, emblem)
	var mark := _label("CS GAME", Vector3(0, 0.045, 0), 0.0, 0.025)
	mark.rotation.x = -PI / 2.0
	mark.modulate = Color("e2e7d8")
	for z in [-3.0, -1.7, -0.4]:
		var origin := Vector3(-9.7, 0.0, z)
		_cylinder(origin + Vector3(0, 0.08, 0), 0.32, 0.16, dark)
		_beam(origin, origin + Vector3(0, 3.0, 0), 0.025, metal)
		for stripe in range(3):
			var colors := [Color("389ccc"), Color("f4f2e5"), Color("3b9672")]
			_box(origin + Vector3(0.43, 2.74 - stripe * 0.23, 0), Vector3(0.85, 0.22, 0.02), _material(colors[stripe]), 0.0, false)
	_box(Vector3(-9.0, 1.7, 3.0), Vector3(0.12, 1.35, 2.4), dark)
	_box(Vector3(-9.0, 0.6, 3.0), Vector3(0.12, 1.2, 0.12), metal, 0.0, false)
	for position in [Vector3(5.5, 0, 8), Vector3(-5.5, 0, 8)]:
		_plant(position)


func _make_campus() -> void:
	var asphalt := _textured_material("paving", Color("555960"), 0.95)
	var facade := _material(Color("e6d7b3"))
	var stone := _material(Color("919a9c"))
	var grass := _material(Color("608447"))
	_box(Vector3(0, -1.08, 0), Vector3(128, 0.36, 128), asphalt)
	# The pale, rounded facade has a grey plinth and tall upper arched windows.
	for segment in range(SEGMENTS):
		var a := (segment + 0.5) * TAU / SEGMENTS
		var yaw := -a - PI / 2.0
		var width := 2.0 * 12.4 * sin(PI / SEGMENTS)
		for level in range(4):
			var opening := segment in [0, 1, 30, 31]
			opening = opening or (level == 3 and segment in [15, 16])
			opening = opening or (level == 0 and segment in [7, 8])
			opening = opening or (level == 1 and segment in [23, 24])
			if not opening:
				_box(_polar(12.4, a, level * 4.0 + 1.55 if level == 0 else level * 4.0 + 2.0), Vector3(width + 0.03, 4.9 if level == 0 else 4.0, 0.25), stone if level == 0 else facade, yaw)
		if segment not in [0, 1, 7, 8, 15, 16, 23, 24, 30, 31] and segment % 2 == 0:
			_window(_polar(12.58, a, 1.5), yaw, 1.45, 2.25)
			_window(_polar(12.58, a, 6.0), yaw, 1.45, 2.2)
			_window(_polar(12.58, a, 11.65), yaw, 1.55, 5.2)
			# Semicircular pale stone trim above each tall upper window.
			for arc in range(8):
				var t0 := PI * arc / 8.0
				var t1 := PI * (arc + 1) / 8.0
				var tangent := Vector3(-sin(a), 0, cos(a))
				var origin := _polar(12.64, a, 14.25)
				_beam(origin + tangent * cos(t0) * 0.85 + Vector3.UP * sin(t0) * 0.85, origin + tangent * cos(t1) * 0.85 + Vector3.UP * sin(t1) * 0.85, 0.055, cream)
		for band in [3.8, 8.0, 15.8]:
			_box(_polar(12.6, a, band), Vector3(width + 0.12, 0.16, 0.24), cream, yaw, false)
		_box(_polar(12.56, segment * TAU / SEGMENTS, 9.9), Vector3(0.12, 12.0, 0.12), cream, -a, false)
	# Front entrance meets the first gallery, like the raised portal in IMG_0050.
	_box(Vector3(0, 3.85, -14.0), Vector3(4.8, 0.3, 5.0), marble)
	for x in [-2.4, 2.4]:
		_box(Vector3(x, 6.0, -13.7), Vector3(0.2, 4.0, 4.6), wood)
	_box(Vector3(0, 7.95, -13.7), Vector3(4.8, 0.1, 4.6), cream)
	_box(Vector3(0, 3.85, -17.5), Vector3(9.5, 0.3, 3.0), paving)
	for x in [-4.7, 4.7]:
		_box(Vector3(x, 8.0, -15.8), Vector3(0.6, 9.0, 0.6), facade)
	_box(Vector3(0, 12.6, -15.8), Vector3(10.0, 0.6, 0.65), facade)
	_label("ATRIUM", Vector3(0, 9.5, -16.16), PI, 0.018)
	for x in [-3.0, 3.0]:
		_stair_flight(x, -0.9, -28.5, -19.0, 4.9)
		for side in [-1.0, 1.0]:
			_beam(Vector3(x + side * 1.15, 0.1, -28.5), Vector3(x + side * 1.15, 5.0, -19.0), 0.045, metal)
	# Side extensions cover the auditorium and internal switchback stairs.
	_box(Vector3(-20, 5.5, -7.3), Vector3(16, 12.8, 0.3), facade)
	_box(Vector3(-20, 5.5, 7.3), Vector3(16, 12.8, 0.3), facade)
	_box(Vector3(-28.2, 5.5, 0), Vector3(0.3, 12.8, 14.6), facade)
	for height in [1.5, 5.5, 9.5]:
		for z in [-5.0, 0.0, 5.0]:
			_window(Vector3(-28.4, height, z), PI / 2.0, 1.6, 2.1)
	# Other buildings were filmed from outside only, so their interiors are closed.
	_campus_block(Vector3(-43, -0.9, 33), Vector3(24, 12, 16), facade)
	_campus_block(Vector3(24, -0.9, 53), Vector3(43, 3.6, 8), _material(Color("d9c995")))
	_campus_block(Vector3(-35, -0.9, -48), Vector3(35, 13, 14), facade)
	# Garden islands, perimeter road, lamps and fence follow IMG_0048–0052.
	for origin in [Vector3(0, -0.9, -40), Vector3(42, -0.9, 3), Vector3(-43, -0.9, 0)]:
		_box(origin, Vector3(19, 0.1, 17), grass)
		for offset in [-6.0, 0.0, 6.0]:
			_tree(origin + Vector3(offset, 0.1, 1.0))
	for x in [-59.0, 59.0]:
		_box(Vector3(x, 1.1, 0), Vector3(0.25, 4.0, 126), stone)
		_box(Vector3(x * 0.95, -0.865, 0), Vector3(0.1, 0.01, 120), _material(Color("d2b33e")), 0.0, false)
	for z in [-63.0, 63.0]:
		_box(Vector3(0, 1.1, z), Vector3(118, 4.0, 0.25), stone)
	for z in [-51.0, -26.0, 0.0, 27.0, 51.0]:
		for x in [-55.0, 55.0]:
			_beam(Vector3(x, -0.9, z), Vector3(x, 5.0, z), 0.08, dark)
			_beam(Vector3(x, 5.0, z), Vector3(x - signf(x) * 1.1, 5.4, z), 0.07, dark)
			_box(Vector3(x - signf(x) * 1.1, 5.4, z), Vector3(0.5, 0.08, 0.3), glow, 0.0, false)
	# Broad outdoor stairs and railings seen behind the main building.
	_stair_flight(-23.0, -0.9, 27.0, 36.0, 2.4)
	_box(Vector3(-23, 1.36, 37.5), Vector3(6, 0.28, 3), paving)
	for x in [-24.2, -21.8]:
		_beam(Vector3(x, 0.1, 27), Vector3(x, 2.5, 36), 0.045, metal)
	# Cover objects make the outdoor approaches playable.
	for point in [Vector3(5,-0.9,35), Vector3(-5,-0.9,38), Vector3(29,-0.9,17), Vector3(-36,-0.9,-15)]:
		_box(point + Vector3(0, 0.75, 0), Vector3(1.6, 1.5, 1.6), wood)
	for point in [Vector3(9,-0.9,-33), Vector3(-11,-0.9,-34)]:
		_box(point + Vector3(0,0.5,0), Vector3(3.0, 1.0, 0.7), wood)


func _campus_block(origin: Vector3, size: Vector3, material: Material) -> void:
	_box(origin + Vector3(0, size.y / 2.0, 0), size, material)
	_box(origin + Vector3(0, size.y + 0.1, 0), Vector3(size.x + 0.3, 0.2, size.z + 0.3), cream)
	for level in range(int(size.y / 4.0)):
		for offset in range(-int(size.x / 2.0) + 2, int(size.x / 2.0), 4):
			_window(origin + Vector3(offset, 2.0 + level * 4.0, -size.z / 2.0 - 0.03), PI, 1.5, 1.8)
	if size.y < 4.0:
		for offset in range(-int(size.x / 2.0) + 2, int(size.x / 2.0), 5):
			_window(origin + Vector3(offset, 1.9, -size.z / 2.0 - 0.03), PI, 1.4, 1.6)


func _tree(origin: Vector3) -> void:
	_box(origin + Vector3(0, 1.45, 0), Vector3(0.25, 2.9, 0.25), wood)
	var leaves := _material(Color("527c42"))
	for offset in [Vector3(0,3.7,0), Vector3(-0.9,3,0), Vector3(0.9,3,0), Vector3(0,3.1,0.9)]:
		var crown := _sphere(origin + offset, 1.5, leaves)
		crown.scale.y = 1.25


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
	for frame in range(8):
		await get_tree().physics_frame
	while NavigationServer3D.map_get_iteration_id(map_rid) == 0:
		await get_tree().physics_frame
	navigation_ready = true


func _closed_door(origin: Vector3, yaw: float) -> void:
	var assembly := Node3D.new()
	assembly.position = origin
	assembly.rotation.y = yaw
	add_child(assembly)
	var frame := _box(Vector3(0, 1.38, 0), Vector3(1.3, 2.76, 0.07), dark, 0.0, false)
	frame.reparent(assembly, false)
	var leaf := _box(Vector3(0, 1.32, -0.045), Vector3(1.08, 2.52, 0.04), _material(Color("3e4852")), 0.0, false)
	leaf.reparent(assembly, false)
	var handle := _box(Vector3(0.38, 1.2, -0.09), Vector3(0.04, 0.18, 0.06), metal, 0.0, false)
	handle.reparent(assembly, false)


func _window(origin: Vector3, yaw: float, width: float, height: float) -> void:
	var assembly := Node3D.new()
	assembly.position = origin
	assembly.rotation.y = yaw
	add_child(assembly)
	var pane := _box(Vector3.ZERO, Vector3(width, height, 0.03), _material(Color("4b6575"), 0.2), 0.0, false)
	pane.reparent(assembly, false)
	for x in [-width / 2.0, 0.0, width / 2.0]:
		var frame := _box(Vector3(x, 0, -0.025), Vector3(0.06, height + 0.08, 0.06), dark, 0.0, false)
		frame.reparent(assembly, false)
	for y in [-height / 2.0, height / 2.0]:
		var frame := _box(Vector3(0, y, -0.025), Vector3(width + 0.08, 0.06, 0.06), dark, 0.0, false)
		frame.reparent(assembly, false)


func _plant(origin: Vector3, scale_factor: float = 1.0) -> void:
	_cylinder(origin + Vector3(0, 0.23, 0) * scale_factor, 0.22 * scale_factor, 0.46 * scale_factor, cream)
	var leaves := _material(Color("3f744e"))
	for branch in range(5):
		var a := TAU * branch / 5.0
		var leaf := _sphere(origin + Vector3(cos(a) * 0.22, 0.7 + branch * 0.06, sin(a) * 0.22) * scale_factor, 0.27 * scale_factor, leaves)
		leaf.scale = Vector3(0.7, 1.25, 0.7)


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
	for point in [a, b, c, a, c, d]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(point.x, point.z))
		surface.add_vertex(point)
