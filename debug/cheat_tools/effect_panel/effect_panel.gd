class_name CTEffectPanel
extends Control

@onready var effect_label: Label = $Wrapper/Items/EffectLabel

@export var effect_id: int

var target: Node3D


func _ready() -> void:
	target = get_parent().owner.get_parent()
	

func _on_add_effect_btn_pressed() -> void:
	ServerRequests.send_add_effect_request(target, effect_id)


func _on_remove_effect_btn_pressed() -> void:
	ServerRequests.send_remove_effect_request(target, effect_id, true)
