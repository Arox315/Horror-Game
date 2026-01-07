class_name EffectBanner
extends Control

@export var effect_icon: Texture2D
@export var max_stacks: int:
	set(value):
		max_stacks = value
		if not label: return
		if value == 1:
			label.visible = false
		else:
			label.visible = true

@export var stacks: String
@export var lifetime: float
@export var is_endless: bool

@onready var icon: TextureRect = $InnerPanelWrapper/InnerPanel/Icon
@onready var diminished_overlay: ColorRect = $InnerPanelWrapper/InnerPanel/DiminishedOverlay
@onready var label: Label = $InnerPanelWrapper/InnerPanel/Label

var tween: Tween


func _ready() -> void:
	tween = create_tween()
	label.text = stacks
	icon.texture = effect_icon
	max_stacks = max_stacks
	
	if not is_endless:
		tween.tween_property(diminished_overlay,"size",Vector2(diminished_overlay.size.x, diminished_overlay.size.x), lifetime)


func update_display(new_stacks: int) -> void:
	if is_endless: return
	if new_stacks <= 0: return
	
	label.text = str(new_stacks)

	tween.kill()
	tween = create_tween()
	
	diminished_overlay.size.y = 0.0
	tween.tween_property(diminished_overlay,"size",Vector2(diminished_overlay.size.x, diminished_overlay.size.x), lifetime)


func delete() -> void:
	tween.kill()
	queue_free()
