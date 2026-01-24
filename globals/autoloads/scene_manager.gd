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
func start_loading_scene(id: int) -> void:
	next_scene = SCENES.get(id, SCENES[scene_id.MAIN_MENU])
	load_scene(loading_screen_scene)


func load_scene(scene_to_load: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene_to_load)
