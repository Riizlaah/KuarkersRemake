class_name Player
extends CharacterBody3D

@onready var label = $Layer1/Control/Label
@onready var camera = $Skeleton3D/Head/Camera3D
@onready var head = $Skeleton3D/Head
@onready var ray_cast = $Skeleton3D/Head/Camera3D/RayCast3D
@onready var texture_rect = $Layer1/Control/TextureRect
@onready var panel = $Layer2/Panel

@export var main_item: BaseObject3D
@export var cam_texture: ViewportTexture

var rad89 = deg_to_rad(89)
var n_rad89 = deg_to_rad(-89)
var unique_id: int
var main_scene = "res://scene/main.tscn"

const SPEED = 15.0
const JUMP_VELOCITY = 13.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var senv: float
var player_name: String

func _ready():
	player_name = "Heker"
	camera.current = true
	senv = 0.25
	camera.far = Settings.render_distance + (Settings.render_distance / 32)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_pressed("jump") and is_on_floor(): velocity.y = JUMP_VELOCITY
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	if head.rotation.y != 0 and velocity.length() != 0.0:
		rotate_y(head.rotation.y)
		head.rotation.y = 0
	move_and_slide()

func _input(event):
	var is_colliding = ray_cast.is_colliding()
	if event is InputEventScreenDrag:
		head.rotate_y(deg_to_rad(-event.relative.x) * senv)
		head.rotation.y = clamp(head.rotation.y, n_rad89, rad89)
		if (head.rotation_degrees.y >= 80) or (head.rotation_degrees.y <= -80): rotate_y(deg_to_rad(-event.relative.x) * senv)
		camera.rotate_x(deg_to_rad(event.relative.y) * senv)
		camera.rotation.x = clamp(camera.rotation.x, n_rad89, rad89)
	if event.is_action_pressed("place") and is_colliding:
		var collider = ray_cast.get_collider()
		if !(collider is Player): collider.get_parent().place_object(ray_cast.get_collision_point() + (ray_cast.get_collision_normal() * main_item.obj_scale), main_item.obj_id)

func _process(_delta):
	label.text = "FPS : " + str(Engine.get_frames_per_second()) + "\n" + str(position)
	if ray_cast.is_colliding(): texture_rect.self_modulate = Color.RED
	else: texture_rect.self_modulate = Color.WHITE

#Controls signal
func _on_control_gui_input(event: InputEvent):
	if event is InputEventScreenTouch and event.is_pressed():
		if ray_cast.get_collider() is BasePlaceable3D: ray_cast.get_collider().free()

func _on_pause_toggled(toggled_on: bool):
	if toggled_on: panel.show()
	else: panel.hide()

func _on_save_pressed():
	for node in get_tree().get_nodes_in_group("layers"): node.hide()
	await get_tree().create_timer(0.15).timeout
	get_parent().save_games()

func get_back():
	get_tree().change_scene_to_file(main_scene)
	return
