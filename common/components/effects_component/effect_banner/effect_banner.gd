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

@onready var bg_active: TextureRect = $BGActive
@onready var bg_diminished: ColorRect = $BGDiminished
@onready var label: Label = $Label

var bg_tween: Tween


func _ready() -> void:
	bg_tween = create_tween()
	label.text = stacks
	bg_active.texture = effect_icon
	max_stacks = max_stacks
	
	if not is_endless:
		bg_tween.tween_property(bg_diminished,"size",Vector2(bg_diminished.size.x, bg_diminished.size.x), lifetime)


func update_display(new_stacks: int) -> void:
	if is_endless: return
	if new_stacks <= 0: return
	
	label.text = str(new_stacks)

	bg_tween.kill()
	bg_tween = create_tween()
	
	bg_diminished.size.y = 0.0
	bg_tween.tween_property(bg_diminished,"size",Vector2(bg_diminished.size.x, bg_diminished.size.x), lifetime)


func delete() -> void:
	bg_tween.kill()
	queue_free()
