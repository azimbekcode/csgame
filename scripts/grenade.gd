extends RigidBody3D

const WEAPONS = preload("res://scripts/weapons.gd")
var kind := "he"
var owner_actor: Node3D
var game: Node3D
var fuse := 2.0

func _ready() -> void:
	mass = 0.3
	collision_layer = 4
	collision_mask = 1
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.08
	collision.shape = sphere
	add_child(collision)
	var mesh := SphereMesh.new()
	mesh.radius = 0.075
	mesh.height = 0.15
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = WEAPONS.material(Color("6b824c") if kind == "he" else Color("acb5be"))
	add_child(visual)
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.45
	physics_material_override.friction = 0.5

func _physics_process(delta: float) -> void:
	fuse -= delta
	if fuse <= 0:
		game.grenade_explode(kind,global_position,owner_actor)
		queue_free()
