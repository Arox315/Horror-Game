extends Node


enum scene_id{
	MAIN_MENU,
	LOBBY,
	PLAYGROUND
}

const STAGES: Dictionary = {
	scene_id.PLAYGROUND: "uid://dvi7lqoafi1cl"
}

const SCENES: Dictionary = {
	scene_id.MAIN_MENU: "uid://c5kb3tpbfje51",
	scene_id.LOBBY: "uid://bwpiufd8m8gmh",
	scene_id.PLAYGROUND: "uid://dvi7lqoafi1cl"
}

var loading_screen_scene: PackedScene = preload("uid://bni1jl5y3211l")
var next_scene: String = SCENES[scene_id.MAIN_MENU]


@rpc("reliable", "authority", "call_local")
func start_loading_scene(id: int, wait_for_all_peers: bool = true) -> void:
	MultiplayerManager.server_current_scene_id = id
	var ls: LoadingScreen = get_tree().current_scene.get_node_or_null("LoadingScreen")
	if not ls:
		push_error("[%s] Loading Screen not fount at %s. Unable to load scene!" % [self, get_tree().current_scene])
		return
	ls.start_loading_new_scene(id, wait_for_all_peers)
