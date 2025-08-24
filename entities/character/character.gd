extends CharacterBody3D

@export var character_color: Color = Color.WHITE
@export var first_person_camera_position: Vector3 = Vector3.ZERO
@export var third_person_camera_position: Vector3 = Vector3(0, 0.8, 1.8)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const CAMERA_ROTATION_SPEED = 50.0 * deg_to_rad(0.022)

@onready var neck := $Neck
@onready var camera: Camera3D = $Neck/Camera3D
@onready var world_model: Node3D = $WorldModel
@onready var body_model: MeshInstance3D = $WorldModel/BodyModel

var direction:Vector3 = Vector3.ZERO
var is_third_person: bool = false

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	# Don't execute code if not authority
	if not is_multiplayer_authority():
		return
	
	# Set camera to authority
	camera.position = first_person_camera_position
	camera.current = is_multiplayer_authority()
	
	# Set random color for 3rd-person mesh
	character_color = Color(RandomColorGenerator.rand_hex())
	body_model.color = character_color
	
	# Hide authority's world model
	hide_world_model()


func _physics_process(delta: float) -> void:
	# Don't execute code if not authority
	if !is_multiplayer_authority():
		return
	
	# toggle 3rd person
	if Input.is_action_just_pressed("change_perspective"):
		toggle_third_person()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	# Don't execute code if not authority
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(deg_to_rad(-event.relative.x * CAMERA_ROTATION_SPEED))
			camera.rotate_x(deg_to_rad(-event.relative.y * CAMERA_ROTATION_SPEED))
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(90))


func toggle_third_person() -> void:
	if is_third_person:
		camera.position = first_person_camera_position
		hide_world_model()
		is_third_person = false
	else:
		camera.position = third_person_camera_position
		show_world_model()
		is_third_person = true
		


func hide_world_model() -> void:
	if not is_instance_valid(world_model):
		return
	for child: MeshInstance3D in world_model.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func show_world_model() -> void:
	if not is_instance_valid(world_model):
		return
		
	for child: MeshInstance3D in world_model.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
