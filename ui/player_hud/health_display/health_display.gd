class_name HealthDisplay
extends MarginContainer

@export var health_component: HealthComponent
@export var fillbar_color: Color

@onready var fillbar: ColorRect = $Wrapper/Healthbar/Fillbar
@onready var label: Label = $Wrapper/Healthbar/Label

var max_health: int = 1: set = _set_max_health
var current_health: int = 1: set = _set_current_health

var fillbar_length: float = 512.0
var fillbar_ratio: float


func _ready() -> void:
	if not health_component: 
		push_error("No HealthComponent set for %s in %s" % [self, owner])
		return
	
	if not owner.is_multiplayer_authority(): 
		set_physics_process(false)
		visible = false
		return
	
	health_component.damaged.connect(_on_damaged)
	health_component.healed.connect(_on_healed)
	health_component.killed.connect(_on_killed)
	health_component.revived.connect(_on_revived)
	
	max_health = health_component.max_health
	current_health = health_component.current_health
	
	fillbar_ratio = fillbar_length / max_health


func set_label() -> void:
	var label_text: String = "%d/%d" % [current_health, max_health]
	label.text = label_text


func _set_current_health(value: int) -> void:
	current_health = clampi(value, 0, max_health)
	fillbar.color.h = clampf(
		(current_health - roundi(max_health * 0.1)) * fillbar_color.h / roundi(max_health * 0.85), 0, fillbar_color.h
	)
	set_label()


func _set_max_health(value: int) -> void:
		max_health = maxi(1, value)
		set_label()


func _on_damaged(amount: int) -> void:
	if amount <= 0: return
	current_health -= amount
	fillbar.size.x = clampf(current_health * fillbar_ratio, 0, fillbar_length)


func _on_healed(amount: int) -> void:
	if amount <= 0: return
	current_health += amount
	fillbar.size.x = clampf(current_health * fillbar_ratio, 0, fillbar_length)


func _on_revived() -> void:
	current_health = max_health
	fillbar.size.x = fillbar_length


func _on_killed() -> void:
	current_health = 0
	fillbar.size.x = 0
