class_name Lobby
extends Control

@onready var stage_selector: OptionButton = $Wrapper/StageSelectPanel/StageSelectWrapper/StageSelector
@onready var start_game_btn: Button = $Wrapper/StageSelectPanel/StageSelectWrapper/StartGameBtn
@onready var connected_players: VBoxContainer = %ConnectedPlayers

var stage_id_offset: int
var connected_player_banner_scene: PackedScene = preload("uid://csixnn6wfsgjd")


func _ready() -> void:
	if multiplayer.is_server():
		var spawn_manager_scene = preload("uid://bj46wjkp0wjls")
		var spawn_manager: LobbySpawnManager = spawn_manager_scene.instantiate()
		add_child(spawn_manager)
		add_connected_player()
	
	for stage_id in SceneManager.STAGES.keys():
		stage_selector.add_item(SceneManager.scene_id.keys()[stage_id], stage_id)
	
	stage_id_offset = SceneManager.STAGES.keys()[0]
	stage_selector.selected = 0
	
	if not multiplayer.is_server():
		stage_selector.disabled = true
		start_game_btn.disabled = true
	
	if MultiplayerManager.is_valid_multiplayer_connection():
		await get_tree().physics_frame
		var game_manager = get_tree().current_scene
		game_manager.update_synchronizers.rpc()


func _on_start_game_btn_pressed() -> void:
	if not multiplayer.is_server(): return
	
	await get_tree().physics_frame
	
	var stage_id: int = stage_selector.selected + stage_id_offset
	SceneManager.start_loading_scene.rpc(stage_id)


func _on_leave_lobby_btn_pressed() -> void:
	MultiplayerManager.terminate_connection()


@rpc("reliable", "any_peer", "call_remote")
func add_connected_player(peer_id: int = 1) -> void:
	var connected_player_banner: ConnectedPlayerBanner = connected_player_banner_scene.instantiate()
	connected_players.add_child(connected_player_banner)
	connected_player_banner.name = str(peer_id)
	connected_player_banner.set_multiplayer_authority(1)
	connected_player_banner.player_name.text = MultiplayerManager.player_names.get(peer_id, "Connecting player...")
	connected_player_banner.player_id.text = str(peer_id)
	

@rpc("reliable", "any_peer", "call_local")
func update_connected_player_name(peer_id: int) -> void:
	connected_players.get_node(str(peer_id)).player_name.text = MultiplayerManager.player_names[peer_id]


@rpc("reliable", "any_peer")
func add_already_connected_players(peer_id: int) -> void:
	for player_id in MultiplayerManager.player_names.keys():
		if player_id == peer_id: continue
		add_connected_player(player_id)


@rpc("reliable","any_peer","call_local")
func delete_connected_player(peer_id: int) -> void:
	if not connected_players.has_node(str(peer_id)): return
	connected_players.get_node(str(peer_id)).queue_free()
