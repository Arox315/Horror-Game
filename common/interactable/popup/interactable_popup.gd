class_name InteractablePopup
extends Label3D

@onready var popup_animation_player: AnimationPlayer = $PopupAnimationPlayer

@export var is_opened: bool = false

func _ready() -> void:
	popup_animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	#popup_content.add_theme_font_size_override("font_size",popup_content.get_theme_default_font_size())


func set_content(content:String) -> void:
	text = content


func open() -> void:
	popup_animation_player.play("open")


func close() -> void:
	popup_animation_player.play("close")
