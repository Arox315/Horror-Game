extends CharacterBody3D

@export var first_person_camera_position: Vector3 = Vector3.ZERO
@export var third_person_camera_position: Vector3 = Vector3(0, 0.8, 1.8)

const BASE_SPEED: float = 5.0
var _speed_multipliers: Dictionary = {}
var current_speed: float

var is_noclip: bool = false
var camera_direction: Vector3 = Vector3.ZERO
var noclip_speed_multiplier: float = 3.0
var noclip_speed_step: float = 0.2

var JUMP_VELOCITY = 4.5
var CAMERA_ROTATION_SPEED = 50.0 * deg_to_rad(0.022)
var game_manager: GameManager

@onready var camera_controller: Node3D = $CameraController
@onready var camera: Camera3D = $CameraController/Camera3D
@onready var camera_controller_anchor: Marker3D = $CameraControllerAnchor
@onready var interact_ray: InteractRay = $CameraControllerAnchor/InteractRay
@onready var world_model: Node3D = $WorldModel
@onready var body_model: MeshInstance3D = $WorldModel/BodyModel
@onready var world_model_anchor: Marker3D = $WorldModel/WorldModelAnchor
@onready var player_type: Control = $Hud/PlayerType
@onready var effects: HBoxContainer = $Hud/EffectsContainer/Effects
@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox: CollisionShape3D = $Hitbox

@onready var position_synchronizer: MultiplayerSynchronizer = $PositionSynchronizer
@onready var model_synchronizer: MultiplayerSynchronizer = $ModelSynchronizer
	

var direction:Vector3 = Vector3.ZERO
var is_third_person: bool = false
var spawn_point_position: Vector3 = Vector3.ZERO

func _enter_tree() -> void:
	# Disable process
	process_mode = Node.PROCESS_MODE_DISABLED
	
	set_multiplayer_authority(name.to_int())
	var hc := $HealthComponent
	hc.died.connect(_on_died)


func _ready() -> void:
	# Set move speed
	update_speed()
	
	# Turn on synchronization visibility
	position_synchronizer.set_visibility_for(0, true)
	model_synchronizer.set_visibility_for(0, true)
	
	game_manager = get_tree().current_scene
	
	# Don't execute code if not authority
	if not is_multiplayer_authority():
		# disable camera if not authority
		camera.set_physics_interpolation_mode(Node.PHYSICS_INTERPOLATION_MODE_OFF)
		camera.set_process(false)
		camera.set_physics_process(false)
		return
	
	# Move to satege spawn point
	position = _get_respawn_point()
	
	# add palyer type to hud
	var player_type_label = Label.new()
	player_type_label.text = "Player" if name.to_int() != 1 else "Host"
	player_type_label.add_theme_font_size_override("font_size",24)
	player_type.add_child(player_type_label)
	
	# Set camera to authority
	camera.position = first_person_camera_position
	camera.current = is_multiplayer_authority()
	
	# Set camera controller settings for interpolation
	camera_controller.top_level = true
	camera_controller.set_physics_interpolation_mode(Node.PHYSICS_INTERPOLATION_MODE_OFF)
	
	# Set random color for 3rd-person mesh
	body_model.color = Color(Utilities.get_random_hex_color())
	
	# Hide authority's world model
	hide_world_model()
	
	if multiplayer.is_server() and OS.has_feature("debug"):
		const CHEAT_PANEL = preload("uid://c8k0dl4dlmk0u")
		var cheat_panel: Control = CHEAT_PANEL.instantiate()
		cheat_panel.hide()
		add_child(cheat_panel)


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
			rotate_y(deg_to_rad(-event.relative.x * CAMERA_ROTATION_SPEED))
			
			camera.rotate_x(deg_to_rad(-event.relative.y * CAMERA_ROTATION_SPEED))
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(90))
			
			interact_ray.rotate_x(deg_to_rad(-event.relative.y * CAMERA_ROTATION_SPEED)) 
			interact_ray.rotation.x = clamp(interact_ray.rotation.x, deg_to_rad(-60), deg_to_rad(90))


func _physics_process(delta: float) -> void:
	# Don't execute code if not authority
	if !is_multiplayer_authority():
		return
	
	if Input.is_action_just_pressed("toggle_cheat_panel") and OS.has_feature("debug"):
		var cheat_panel: Control = get_node_or_null("CheatPanel")
		if cheat_panel:
			if cheat_panel.visible:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				cheat_panel.hide()
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				cheat_panel.show()
	
	
	# toggle 3rd person
	if Input.is_action_just_pressed("change_perspective"):
		toggle_third_person()
	
	var input_dir := Input.get_vector("left", "right", "forward", "back").normalized()
	direction = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	camera_direction = camera_controller.transform.basis * camera.transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	
	if not _handle_noclip(delta):
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
	
		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
		
		move_and_slide()


func _process(_delta: float) -> void:
	camera_controller.global_position = camera_controller_anchor.get_global_transform_interpolated().origin
	body_model.global_position = world_model_anchor.get_global_transform_interpolated().origin
	global_basis = global_basis.orthonormalized()
	camera_controller.global_basis = global_basis.orthonormalized()


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
	for child in world_model.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func show_world_model() -> void:
	if not is_instance_valid(world_model):
		return
		
	for child in world_model.get_children():
		if child is MeshInstance3D:
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func set_speed_multiplier(key: String, value: Variant) -> void:
	_speed_multipliers[key] = value
	update_speed()


func get_speed_multiplier(key:String) -> Variant:
	return _speed_multipliers.get(key)


func remove_speed_multiplier(key:String) -> void:
	_speed_multipliers.erase(key)
	update_speed()


func update_speed() -> void:
	var gained_speed: float = 0.0
	for value in _speed_multipliers.values():
		gained_speed += value
	
	current_speed = BASE_SPEED + gained_speed


@rpc("reliable", "any_peer", "call_local")
func respawn() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	
	if self is CharacterBody3D: velocity = Vector3.ZERO
	
	position = _get_respawn_point()


func _get_respawn_point() -> Vector3:
	var spawn_point = game_manager.main_scene.get_node_or_null("PlayersSpawnPoint")
	if spawn_point:  
		return spawn_point.global_position
	return Vector3.ZERO


func _on_died() -> void:
	await get_tree().physics_frame # makes sure this function is executed after the damage has been dealt
	ServerRequests.send_reset_current_health_request(self)
	respawn.rpc_id(get_multiplayer_authority())
	
	if multiplayer.is_server(): print("[%s] Died. Respawning..." % self)


@rpc("reliable", "any_peer", "call_local")
func enable_process() -> void:
	# Enable process
	process_mode = Node.PROCESS_MODE_ALWAYS


func _handle_noclip(delta: float) -> bool:
	if not is_noclip: return false
	
	velocity = camera_direction * current_speed
	global_position += velocity * delta
	
	if Input.is_action_just_pressed("noclip_speed_up"):
		noclip_speed_multiplier += noclip_speed_step
		noclip_speed_multiplier = min(noclip_speed_multiplier, 100.0)
		set_speed_multiplier("NoclipSpeedMult", noclip_speed_multiplier)
	
	if Input.is_action_just_pressed("noclip_speed_down"):
		noclip_speed_multiplier -= noclip_speed_step
		noclip_speed_multiplier = max(noclip_speed_multiplier, 0.1)
		set_speed_multiplier("NoclipSpeedMult", noclip_speed_multiplier) 
	
	return true


func toggle_noclip() -> void:
	is_noclip = not is_noclip
	hitbox.disabled = is_noclip
	
	if is_noclip:
		set_speed_multiplier("NoclipSpeedMult", noclip_speed_multiplier)
	else:
		remove_speed_multiplier("NoclipSpeedMult")
