extends Node


enum scene_id{
	MAIN_MENU,
	LOBBY,
	PLAYGROUND,
	TEST_STAGE_01
}

const STAGES: Dictionary = {
	scene_id.PLAYGROUND: "uid://dvi7lqoafi1cl",
	scene_id.TEST_STAGE_01: "uid://n71req146s43"
}

const SCENES: Dictionary = {
	scene_id.MAIN_MENU: "uid://c5kb3tpbfje51",
	scene_id.LOBBY: "uid://bwpiufd8m8gmh",
	scene_id.PLAYGROUND: "uid://dvi7lqoafi1cl",
	scene_id.TEST_STAGE_01: "uid://n71req146s43"
}

var loading_screen_scene: PackedScene = preload("uid://bni1jl5y3211l")
var next_scene: String = SCENES[scene_id.MAIN_MENU]

var _game_manager: GameManager


func _ready() -> void:
	_game_manager = get_tree().current_scene


@rpc("reliable", "authority", "call_local")
func start_loading_scene(id: int, wait_for_all_peers: bool = true) -> void:
	MultiplayerManager.server_current_scene_id = id
	_game_manager.loading_screen.start_loading_new_scene(id, wait_for_all_peers)
