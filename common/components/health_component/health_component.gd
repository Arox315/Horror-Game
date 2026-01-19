class_name HealthComponent
extends Node

signal died

@export var max_health: int = 10
@export var current_health: int = 10: set = _set_current_health

@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer


func _enter_tree() -> void:
	set_multiplayer_authority(1)


func _ready() -> void:
	current_health = current_health
	

func damage(amount: int) -> void:
	if amount <= 0: return
	current_health -= amount
	print("[%s] Damaged for: %d" % [owner, amount])


func heal(amount: int) -> void:
	if amount <= 0: return
	current_health += amount
	print("[%s] Healed for: %d" % [owner, amount])


func reset_current_health() -> void:
	_set_current_health(max_health)


func _set_current_health(value: int) -> void:
	current_health = clampi(value, 0, max_health)
	if current_health <= 0:
		died.emit()
