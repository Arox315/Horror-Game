class_name AcceleratingMoveSpeed
extends Effect


func _ready() -> void:
	default_value = target.SPEED
	super()


func update_effect() -> void:
	pass


var cooldown: float = 1.0 #one second 
var elapsed: float = cooldown #this makes sure the first incrementation of speed happens at the time of getting this effect (rather than after 1 sec)
func apply_effect(delta: float) -> void:
	# linearly go from base speed to base + uptime * amount - 1 (ends on reaching this value)
	target.SPEED = lerp(target.SPEED, target.SPEED + amount_per_stack, delta)
	# increment base speed by amount every second up until base + uptime * amount - 1 (ends just before incrementing again to base + uptime * amount)
	#elapsed += delta
	#if elapsed >= cooldown:
		#target.SPEED += amount_per_stack
		#elapsed = 0.0


func on_finished() -> void:
	target.SPEED = default_value
