class_name LoadingScreen
extends Control


var ready_clients: Dictionary = {}
var is_loading: bool = true
var progress: Array = []
var next_scene: String
#func _enter_tree() -> void:
	#ready_clients[multiplayer.multiplayer_peer.get_unique_id()] = false
	#for peer in multiplayer.get_peers():
		#ready_clients[peer] = false


func _ready() -> void:
	#MultiplayerManager.set_client_not_ready(multiplayer.multiplayer_peer.get_unique_id())
	next_scene = SceneManager.SCENES[SceneManager.scene_id.MAIN_MENU]
	ResourceLoader.load_threaded_request(next_scene)
	

func _process(_delta: float) -> void:
	if not is_loading: return
	
	ResourceLoader.load_threaded_get_status(next_scene, progress)
	%LoadingProgress.text = str(roundi(progress[0]*100))+"%"
	
	if progress[0] == 1.0:
		is_loading = false
		var scene_to_load: PackedScene = ResourceLoader.load_threaded_get(next_scene)
		_load_scene(scene_to_load)
		await  get_tree().create_timer(2).timeout
		_disable()


func start_loading_new_scene(scene_id: int) -> void:
	next_scene = SceneManager.SCENES.get(scene_id, SceneManager.SCENES[SceneManager.scene_id.MAIN_MENU])
	ResourceLoader.load_threaded_request(next_scene)
	_enable()


func _load_scene(scene_to_load: PackedScene) -> void:
	var new_scene = scene_to_load.instantiate()
	owner.add_child(new_scene)
	
	var previous_scene = owner.current_scene
	owner.current_scene = new_scene
	if previous_scene: previous_scene.queue_free()


func _disable() -> void:
	is_loading = false
	set_process(false)
	hide()


func _enable() -> void:
	is_loading = true
	set_process(true)
	show()
