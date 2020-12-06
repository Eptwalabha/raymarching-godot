extends KinematicBody


onready var head := $Head as Spatial
onready var camera := $Head/Camera as Camera
onready var ground := $Ground as RayCast

export(float) var mouse_sensitivity := -.3

export(float) var speed := 3.0
export(float) var acceleration := 10.0

var camera_angle := 0.0
var velocity = Vector3()
var gravity_vector : Vector3 = Vector3.ZERO

const MAX_GRAVITY := 20.0
const GRAVITY := 10.0;
const MAX_SLOP := 2.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(deg2rad(event.relative.x * mouse_sensitivity))

		var change = event.relative.y * mouse_sensitivity
		if change + camera_angle < 90 and change + camera_angle > -90:
			camera.rotate_x(deg2rad(change))
			camera_angle = camera_angle + change

func _physics_process(delta: float) -> void:
	var direction := Vector3()
	var aim = camera.get_global_transform().basis
	
	if Input.is_action_pressed("move_forward"):
		direction -= aim.z
	if Input.is_action_pressed("move_backward"):
		direction += aim.z
	if Input.is_action_pressed("move_left"):
		direction -= aim.x
	if Input.is_action_pressed("move_right"):
		direction += aim.x

	var dir = Vector2(direction.x, direction.z).normalized()
	velocity.x = lerp(velocity.x, dir.x * speed, acceleration * delta)
	velocity.z = lerp(velocity.z, dir.y * speed, acceleration * delta)
	
	if not is_on_floor():
		gravity_vector += Vector3.DOWN * GRAVITY * delta
	elif is_on_floor() and ground.is_colliding():
		gravity_vector = -get_floor_normal() * -GRAVITY
	else:
		gravity_vector = -get_floor_normal()
	
	if gravity_vector.y > MAX_GRAVITY:
		gravity_vector.y = MAX_GRAVITY
	
	velocity.x += gravity_vector.x
	velocity.y = gravity_vector.y
	velocity.z += gravity_vector.z

	velocity = move_and_slide_with_snap(velocity, Vector3(0, -1, 0), Vector3.UP, true, 4, MAX_SLOP)
