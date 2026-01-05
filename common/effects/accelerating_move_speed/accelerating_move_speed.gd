class_name AcceleratingMoveSpeed
extends Effect


func update_effect() -> void:
	pass

# This makes sure the first incrementation of speed happens at the time of getting this effect 
# (rather than after overtime interval)
var elapsed: float = overtime_interval
func apply_effect(delta: float) -> void:
	# Linearly go from base speed to base + uptime * amount - 1 (ends on reaching this value)
	var current_amount = target.get_speed_multiplier(name) if target.get_speed_multiplier(name) else 0.0
	target.set_speed_multiplier(name, lerp(current_amount, current_amount + amount_per_stack, delta))
	
	# Increment base speed by amount every second up until base + uptime * amount - 1 (ends just before incrementing again to base + uptime * amount)
	#elapsed += delta
	#if elapsed >= overtime_interval:
		#var current_amount = target.get_speed_multiplier(name) if target.get_speed_multiplier(name) else 0.0
		#target.set_speed_multiplier(name, current_amount + amount_per_stack)
		#elapsed = 0.0


func on_finished() -> void:
	target.remove_speed_multiplier(name)


func on_deleted() -> void:
	pass
