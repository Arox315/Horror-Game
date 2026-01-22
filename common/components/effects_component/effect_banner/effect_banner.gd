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

@export var current_stacks: int
@export var stack_duration: float
@export var is_endless: bool
@export var is_reversed: bool
@export var regenerates_stacks: bool
@export var is_permanent: bool

@onready var icon: TextureRect = $InnerPanelWrapper/InnerPanel/Icon
@onready var diminished_overlay: ColorRect = $InnerPanelWrapper/InnerPanel/DiminishedOverlay
@onready var label: Label = $InnerPanelWrapper/InnerPanel/Label

var tween: Tween
var is_update_locked: bool = false
var is_update_reversed_locked: bool = false

func _ready() -> void:
	label.text = str(current_stacks)
	icon.texture = effect_icon
	max_stacks = max_stacks
	
	if is_reversed:
		diminished_overlay.size.y = diminished_overlay.size.x
		if current_stacks == max_stacks:
			diminished_overlay.size.y = 0.0
		else:
			if regenerates_stacks:
				tween = create_tween()
				tween.tween_property(diminished_overlay,"size",Vector2(diminished_overlay.size.x, 0.0), stack_duration)
	else:
		if not is_endless:
			tween = create_tween()
			tween.tween_property(diminished_overlay,"size",Vector2(diminished_overlay.size.x, diminished_overlay.size.x), stack_duration)


func update_display(new_stacks: int) -> void:
	if is_reversed:
		_update_display_reversed(new_stacks)
	else:
		_update_display(new_stacks)


func delete() -> void:
	tween.kill()
	queue_free()


func set_is_update_locked(value: bool) -> void:
	is_update_locked = value
	if is_update_locked:
		if tween.is_valid(): tween.stop()
	else:
		if tween.is_valid(): tween.play()


func set_is_update_reversed_locked(value: bool) -> void:
	is_update_reversed_locked = value
	if is_update_reversed_locked:
		if tween.is_valid(): tween.stop()
	else:
		if tween.is_valid(): tween.play()


func _update_display(new_stacks: int) -> void:
	if new_stacks <= 0:
		if is_permanent: visible = false
		return
	
	if not visible: visible = true
	
	label.text = str(new_stacks)
	current_stacks = new_stacks
	
	if not is_endless and not is_update_locked:
		if tween: tween.kill()
		tween = create_tween()
		
		diminished_overlay.size.y = 0.0
		tween.tween_property(diminished_overlay,"size",Vector2(diminished_overlay.size.x, diminished_overlay.size.x), stack_duration)


func _update_display_reversed(new_stacks: int) -> void:
	if new_stacks >= max_stacks: 
		label.text = str(max_stacks)
		current_stacks = max_stacks
		return
	
	label.text = str(new_stacks)
	current_stacks = new_stacks
	
	if regenerates_stacks and not is_update_reversed_locked:
		if tween: tween.kill()
		tween = create_tween()
		
		diminished_overlay.size.y = diminished_overlay.size.x
		tween.tween_property(diminished_overlay,"size",Vector2(diminished_overlay.size.x, 0.0), stack_duration)

	
