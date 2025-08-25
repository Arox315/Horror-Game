class_name InteractableObject
extends Node3D

@export var prompt_message: String = "Press [{str}] to interact"
@export var prompt_input: String = "interact"

var interactable_trigger: InteractableTrigger

func _ready() -> void:
	interactable_trigger = get_node("InteractableTrigger")
	
	if not interactable_trigger:
		printerr("Interactable trigger not set for interactable object: ", self)
	else:
		interactable_trigger.interacted.connect(_on_interacted)
		interactable_trigger.prompt_message = prompt_message
		interactable_trigger.prompt_input = prompt_input
		interactable_trigger.interactable_popup.set_content(interactable_trigger.get_prompt())


func update_prompt_message(new_prompt: String) -> void:
	prompt_message = new_prompt
	interactable_trigger.prompt_message = prompt_message
	interactable_trigger.interactable_popup.set_content(interactable_trigger.get_prompt())


func update_prompt_input(new_input: String) -> void:
	prompt_input = new_input
	interactable_trigger.prompt_input = prompt_input


func _on_interacted(body:Variant) -> void:
	var mess:String = "Body: {body}, Interacted with object: {obj}"
	print_debug(mess.format({"body":body,"obj":self}))
