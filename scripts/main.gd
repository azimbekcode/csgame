extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")


func _ready() -> void:
	_make_box(Vector3(0, -0.15, 0), Vector3(20, 0.3, 20), Color(0.28, 0.30, 0.31))

	# Temporary walls for movement testing; the photo-based map will replace them.
	_make_box(Vector3(0, 1.8, -10), Vector3(20, 3.6, 0.4), Color(0.48, 0.48, 0.48))
	_make_box(Vector3(0, 1.8, 10), Vector3(20, 3.6, 0.4), Color(0.48, 0.48, 0.48))
	_make_box(Vector3(-10, 1.8, 0), Vector3(0.4, 3.6, 20), Color(0.48, 0.48, 0.48))
	_make_box(Vector3(10, 1.8, 0), Vector3(0.4, 3.6, 20), Color(0.48, 0.48, 0.48))

	_make_box(Vector3(-3, 0.65, 0), Vector3(2.2, 1.3, 1.2), Color(0.40, 0.34, 0.27))
	_make_box(Vector3(3, 0.65, -3), Vector3(1.5, 1.3, 2.0), Color(0.40, 0.34, 0.27))

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 1.1
	add_child(light)

	_spawn_player()


func _make_box(box_position: Vector3, box_size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = box_position

	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box_size
	collision.shape = box_shape
	body.add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	mesh_instance.mesh = box_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	add_child(body)


func _spawn_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0, 0.1, 6)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 1.55, 0)
	camera.current = true
	player.add_child(camera)

	add_child(player)
