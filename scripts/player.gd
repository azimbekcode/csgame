extends CharacterBody3D

@export var move_speed: float = 5.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002

var gravity: float = 9.8
var view_camera: Camera3D


func _ready() -> void:
	view_camera = $Camera3D
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		view_camera.rotate_x(-event.relative.y * mouse_sensitivity)
		view_camera.rotation.x = clampf(view_camera.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_vector.y += 1.0
	input_vector = input_vector.normalized()

	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	if direction.length() > 0.0:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity

	move_and_slide()
