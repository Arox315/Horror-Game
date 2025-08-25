class_name InteractablePopup
extends Label3D


func _ready() -> void:
	pass
	#popup_content.add_theme_font_size_override("font_size",popup_content.get_theme_default_font_size())


func set_content(content:String) -> void:
	text = content
