extends CharacterBody3D

@onready var head = $Head
@onready var camera = $Head/Camera3D
var speed = 20
var senv = 0.25
var max_y_rot = deg_to_rad(81)

func _physics_process(delta):
	var input = Input.get_vector("a", "d", "w", "s")
	if !is_on_floor(): velocity.y -= 40 * delta
	elif Input.is_action_pressed("jump"): velocity.y = 50
	#var height = Input.get_axis("ui_down", "ui_up")
	var dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	if dir:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	move_and_slide()

func _input(event: InputEvent):
	if event is InputEventScreenDrag:
		head.rotate_y(deg_to_rad(-event.relative.x) * senv)
		if head.rotation_degrees.y < -80 or head.rotation_degrees.y > 80: 
			rotate_y(deg_to_rad(-event.relative.x) * 0.05)
		head.rotation.y = clamp(head.rotation.y, -max_y_rot, max_y_rot)
		camera.rotate_x(deg_to_rad(-event.relative.y * senv))
		camera.rotation.x = clamp(camera.rotation.x, -max_y_rot, max_y_rot)
