class_name HealthRegeneration
extends Effect

var target_health_component: HealthComponent


func _ready() -> void:
	target_health_component = target.get_node_or_null("HealthComponent")
	if target_health_component:
		target_health_component.damaged.connect(_handle_damaged)
	super()


func update_effect() -> void:
	pass


var elapsed: float = 0.0
func apply_effect(delta: float) -> void:
	if not target_health_component: return
	
	elapsed += delta
	
	if elapsed >= tick_interval:
		target_health_component.heal(int(amount_per_stack))
		elapsed = 0.0


func on_finished() -> void:
	pass


func on_deleted() -> void:
	pass


func _handle_damaged(_amount: int) -> void:
	toggle_cooldown()
	decrement_stack()
