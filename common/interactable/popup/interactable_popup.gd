class_name InteractablePopup
extends Label3D

@onready var popup_animation_player: AnimationPlayer = $PopupAnimationPlayer
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

@export var is_opened: bool = false


func _ready() -> void:
	popup_animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS


func set_content(content:String) -> void:
	text = content


func open() -> void:
	popup_animation_player.play("open")


func close() -> void:
	popup_animation_player.play("close")
