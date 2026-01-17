class_name TestEffect01
extends Effect


func _ready() -> void:
	if target.is_in_group("Players"):
		target.test.connect(decrement_stack)
	super()


func update_effect() -> void:
	pass


func apply_effect(_delta: float) -> void:
	pass


func on_finished() -> void:
	pass


func on_deleted() -> void:
	pass
