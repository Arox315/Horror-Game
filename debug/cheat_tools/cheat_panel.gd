extends Control

# Health
@onready var add_health_btn: Button = $TabContainer/Player/ToolsList/HealthPanelWrapper/HealthPanel/AddHealthPanel/AddHealthBtn
@onready var sub_health_btn: Button = $TabContainer/Player/ToolsList/HealthPanelWrapper/HealthPanel/SubHealthPanel/SubHealthBtn
@onready var invlunerable_btn: CheckButton = $TabContainer/Player/ToolsList/HealthPanelWrapper/HealthPanel/InvulnerablePanel/InvlunerableBtn
@onready var god_mode_btn: CheckButton = $TabContainer/Player/ToolsList/HealthPanelWrapper/HealthPanel/GodModePanel/GodModeBtn
@onready var reset_health_btn: Button = $TabContainer/Player/ToolsList/HealthPanelWrapper/HealthPanel/ResetHealthPanel/ResetHealthBtn
@onready var force_kill_btn: Button = $TabContainer/Player/ToolsList/HealthPanelWrapper/HealthPanel/ForceKillPanel/ForceKillBtn

@onready var add_health_number: SpinBox = $TabContainer/Player/ToolsList/HealthPanelWrapper/HealthPanel/AddHealthPanel/AddHealthNumber
@onready var sub_health_number: SpinBox = $TabContainer/Player/ToolsList/HealthPanelWrapper/HealthPanel/SubHealthPanel/SubHealthNumber

# Movement
@onready var no_clip_btn: CheckButton = $TabContainer/Player/ToolsList/MovementPanelWrapper/MovementsPanel/NoClipPannel/NoClipBtn
@onready var no_collision_no_clip_btn: CheckButton = $TabContainer/Player/ToolsList/MovementPanelWrapper/MovementsPanel/NoClipWithNoCollision/NoCollisionNoClipBtn


func _ready() -> void:
	pass


func _on_add_health_btn_pressed() -> void:
	var amount: int = int(add_health_number.value)
	ServerRequests.send_heal_request(get_parent(), amount)


func _on_sub_health_btn_pressed() -> void:
	var amount: int = int(sub_health_number.value)
	ServerRequests.send_damage_request(get_parent(), amount)


func _on_reset_health_btn_pressed() -> void:
	ServerRequests.send_reset_current_health_request(get_parent())


func _on_force_kill_btn_pressed() -> void:
	ServerRequests.send_force_kill_request(get_parent())


func _on_invlunerable_btn_toggled(toggled_on: bool) -> void:
	ServerRequests.send_set_invulnerability_request(get_parent(), toggled_on)


func _on_god_mode_btn_toggled(toggled_on: bool) -> void:
	ServerRequests.send_set_godmode_request(get_parent(), toggled_on)


func _on_no_clip_btn_toggled(_toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_no_collision_no_clip_btn_toggled(_toggled_on: bool) -> void:
	pass # Replace with function body.
