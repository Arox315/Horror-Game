class_name InteractableObject
extends Node3D

@export var prompt_message: String = "Press [{str}] to interact"
@export var prompt_input: String = "interact"

var interactable_triggers: Dictionary[String,InteractableTrigger]

func _ready() -> void:
	assign_triggers()
	
	if not interactable_triggers:
		printerr("No InteractableTrigger set for interactable object: ", self)
	else:
		for interactable_trigger in interactable_triggers.values():
			interactable_trigger.interacted.connect(_on_interacted.bind(interactable_trigger))
			interactable_trigger.prompt_message = prompt_message
			interactable_trigger.prompt_input = prompt_input
			interactable_trigger.interactable_popup.set_content(interactable_trigger.get_prompt())


func update_prompt_message(new_prompt_message: String) -> void:
	prompt_message = new_prompt_message
	for interactable_trigger in interactable_triggers.values():
		interactable_trigger.prompt_message = prompt_message
		interactable_trigger.interactable_popup.set_content(interactable_trigger.get_prompt())


func update_prompt_input(new_prompt_input: String) -> void:
	prompt_input = new_prompt_input
	for interactable_trigger in interactable_triggers.values():
		interactable_trigger.prompt_input = prompt_input


func assign_triggers() -> void:
	for child in get_children():
		if child is InteractableTrigger:
			interactable_triggers[child.name] = child


func lock_all_triggers() -> void:
	for interactable_trigger in interactable_triggers.values():
		interactable_trigger.lock()


func unlock_all_triggers() -> void:
	for interactable_trigger in interactable_triggers.values():
		interactable_trigger.unlock()


func disable_all_triggers() -> void:
	for interactable_trigger in interactable_triggers.values():
		interactable_trigger.disable()


func enable_all_triggers() -> void:
	for interactable_trigger in interactable_triggers.values():
		interactable_trigger.enable()


func _on_interacted(body:Variant, sender: InteractableTrigger) -> void:
	var mess:String = "{body}, Interacted with object: {obj} via: {trig}"
	print_debug(mess.format({"body":body,"obj":self,"trig":sender}))
