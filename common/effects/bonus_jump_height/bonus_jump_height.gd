class_name BonusJumpHeight
extends Effect


func _ready() -> void:
	default_value = target.JUMP_VELOCITY
	super()


func apply_effect(_delta: float) -> void:
	pass


func update_effect() -> void:
	target.JUMP_VELOCITY = default_value + (current_stacks * amount_per_stack)


func on_finished() -> void:
	pass
