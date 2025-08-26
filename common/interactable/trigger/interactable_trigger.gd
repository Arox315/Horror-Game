class_name InteractableTrigger
extends CollisionObject3D

signal interacted(body: Variant)

@export_group("Flags")
@export var can_interact: bool = true
@export var hidden_interacable: bool = false

var prompt_message: String = "Press [{str}] to interact"
var prompt_input: String = "interact"
var is_locked: bool = false

@onready var trigger_area: CollisionShape3D = $TriggerArea
@onready var interactable_popup: InteractablePopup = $InteractablePopup


func _ready() -> void:
	# set collisions to 2nd layer
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(2, true)
	set_collision_mask_value(2, true)
	
	if not can_interact:
		disable()
	else:
		enable()
	
	hide_popup()


func interact(body: Variant) -> void:
	interacted.emit(body)


func disable() -> void:
	visible = false
	trigger_area.disabled = true
	can_interact = false


func enable() -> void:
	visible = true
	trigger_area.disabled = false
	can_interact = true


func lock() -> void:
	is_locked = true


func unlock() -> void:
	is_locked = false


func make_hidden() -> void:
	hidden_interacable = true


func make_visible() -> void:
	hidden_interacable = false


func get_prompt():
	var key_name = ""
	for action in InputMap.action_get_events(prompt_input):
		if action is InputEventKey:
			key_name = action.as_text_physical_keycode()
			break
	return prompt_message.format({"str":key_name})


func show_popup() -> void:
	if hidden_interacable: return
	if interactable_popup.is_opened: return
	interactable_popup.open()


func hide_popup() -> void:
	if not interactable_popup.is_opened: return
	interactable_popup.close()
