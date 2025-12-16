class_name EffectBanner
extends Control

@export var diminished_color: Color
@export var active_color: Color
@export var stacks: String
@export var lifetime: float
@export var is_endless: bool

@onready var bg_diminished: ColorRect = $BGDiminished
@onready var bg_active: ColorRect = $BGActive
@onready var label: Label = $Label

var bg_tween: Tween
var pos_tween: Tween

func _ready() -> void:
	bg_tween = create_tween()
	pos_tween = create_tween()
	label.text = stacks
	bg_diminished.color = diminished_color
	bg_active.color = active_color
	if not is_endless:
		bg_tween.tween_property(bg_active,"size",Vector2(bg_active.size.y, 0.0), lifetime)
		pos_tween.tween_property(bg_active,"position",Vector2(bg_active.position.y, bg_active.size.x), lifetime)


func update_display(new_stacks: int) -> void:
	if new_stacks <= 0: return
	
	label.text = str(new_stacks)

	if is_endless: return
	
	bg_tween.kill()
	pos_tween.kill()
	
	bg_tween = create_tween()
	pos_tween = create_tween()
	
	bg_active.size.y = bg_active.size.x
	bg_active.position.y = 0.0
	
	bg_tween.tween_property(bg_active,"size",Vector2(bg_active.size.y, 0.0), lifetime)
	pos_tween.tween_property(bg_active,"position",Vector2(bg_active.position.y, bg_active.size.x), lifetime)


func delete() -> void:
	bg_tween.kill()
	pos_tween.kill()
	queue_free()
