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
func _start_loading_scene(id: int) -> void:
	next_scene = SCENES.get(id, SCENES[scene_id.MAIN_MENU])
	load_scene(loading_screen_scene)


func load_scene(scene_to_load: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene_to_load)


@rpc("reliable", "authority", "call_local")
func start_loading_scene(id: int) -> void:
	var ls: LoadingScreen = get_tree().root.get_node("Game").get_node("LoadingScreen")
	ls.start_loading_new_scene(id)
	#next_scene = SCENES.get(id, SCENES[scene_id.MAIN_MENU])
	#var current_scene = get_tree().root.get_node("Game").get_node("LoadingScreen").current_scene
	#change_scene(current_scene, load(next_scene))


func change_scene(current_scene: Node, scene_to_load: PackedScene) -> void:
	var new_scene = scene_to_load.instantiate()
	get_tree().root.get_node("Game").add_child(new_scene)
	
	var previous_scene = current_scene
	current_scene = new_scene
	if previous_scene: previous_scene.queue_free()
