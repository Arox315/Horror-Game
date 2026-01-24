extends Control

@onready var stage_selector: OptionButton = $Wrapper/StageSelectPanel/StageSelectWrapper/StageSelector
@onready var start_game_btn: Button = $Wrapper/StageSelectPanel/StageSelectWrapper/StartGameBtn

var stage_id_offset: int

func _ready() -> void:
	if multiplayer.is_server():
		var spawn_manager_scene = preload("uid://bj46wjkp0wjls")
		var spawn_manager = spawn_manager_scene.instantiate()
		add_child(spawn_manager)
	
	for stage_id in SceneManager.STAGES.keys():
		stage_selector.add_item(SceneManager.scene_id.keys()[stage_id], stage_id)
	
	stage_id_offset = SceneManager.STAGES.keys()[0]
	stage_selector.selected = 0
	
	if not multiplayer.is_server():
		stage_selector.disabled = true
		start_game_btn.disabled = true


func _on_start_game_btn_pressed() -> void:
	if not multiplayer.is_server(): return
	print("Loading %s..." % stage_selector.get_item_text(stage_selector.selected))
	
	var stage_id: int = stage_selector.selected + stage_id_offset
	SceneManager.start_loading_scene.rpc(stage_id)
	#MultiplayerManager.load_new_scene_from_id.rpc(stage_selector.selected)


func _on_leave_lobby_btn_pressed() -> void:
	MultiplayerManager.terminate_connection()
