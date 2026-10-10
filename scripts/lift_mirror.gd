extends Node3D
## Planar reflection of the shared 3D world, including the player's mirror-only body.
var viewport: SubViewport
var camera: Camera3D
var mirror_surface: MeshInstance3D
var frame_count := 0

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.name = "MirrorViewport"
	viewport.size = Vector2i(384,428)
	viewport.world_3d = get_world_3d()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	camera = Camera3D.new()
	camera.cull_mask = 1|2
	camera.current = true
	viewport.add_child(camera)
	mirror_surface = MeshInstance3D.new()
	mirror_surface.name = "ReflectionSurface"
	mirror_surface.layers = 4
	var quad := QuadMesh.new()
	quad.size = Vector2(1.3,1.45)
	mirror_surface.mesh = quad
	mirror_surface.rotation.y = -PI/2
	mirror_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	mirror_surface.material_override = material
	add_child(mirror_surface)

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("human_player") as CharacterBody3D
	if not is_instance_valid(player): return
	var normal := global_basis*Vector3.LEFT
	var eye: Vector3 = player.view_camera.global_position
	var distance := normal.dot(eye-global_position)
	var nearby := distance>0.1 and distance<3.0 and eye.distance_to(global_position)<4.0
	if not nearby:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	camera.global_position = eye-2*distance*normal
	camera.look_at(camera.global_position+normal,Vector3.UP)
	var centre := global_position-camera.global_position
	var offset := Vector2(centre.dot(camera.global_basis.x),centre.dot(camera.global_basis.y))
	camera.set_frustum(1.45,offset,maxf(0.05,distance-0.015),80)
	# Mirror surfaces use their own layer to avoid recursive feedback.
	frame_count += 1
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE if frame_count%2==0 else SubViewport.UPDATE_DISABLED
