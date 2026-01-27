class_name LoadingScreen
extends CanvasLayer


var ready_clients: Dictionary = {}
var is_loading: bool = true
var progress: Array = []
var next_scene: String
var _wait_for_all_peers: bool = true


func _ready() -> void:
	MultiplayerManager.all_peers_ready.connect(_on_all_peers_ready)
	_set_next_scene(SceneManager.scene_id.MAIN_MENU)
	ResourceLoader.load_threaded_request(next_scene)


func _process(_delta: float) -> void:
	if not is_loading: return
	
	ResourceLoader.load_threaded_get_status(next_scene, progress)
	%LoadingProgress.text = str(roundi(progress[0]*100))+"%"
	
	if progress[0] == 1.0:
		is_loading = false
		var scene_to_load: PackedScene = ResourceLoader.load_threaded_get(next_scene)
		_load_scene(scene_to_load)
		
		if not multiplayer.multiplayer_peer:
			_disable()
			return
			
		if not multiplayer.get_peers().is_empty():
			%LoadingText.text = "Waiting for other players..."
			
		# Arbitrary load time for players
		if multiplayer.multiplayer_peer.get_unique_id() != 1:
			await get_tree().create_timer(1).timeout
		
		if multiplayer.is_server():
			MultiplayerManager.client_ready()
		else:
			MultiplayerManager.client_ready.rpc_id(1)
			
		if not _wait_for_all_peers:
			_disable()


func start_loading_new_scene(scene_id: int, wait_for_all_peers: bool = true) -> void:
	if multiplayer.multiplayer_peer:
		if multiplayer.multiplayer_peer.get_connection_status() == multiplayer.multiplayer_peer.CONNECTION_CONNECTED:
			if multiplayer.is_server():
				MultiplayerManager.set_clinet_not_ready()
			else:
				MultiplayerManager.set_clinet_not_ready.rpc_id(1)
			_wait_for_all_peers = wait_for_all_peers
	
	await get_tree().physics_frame
	
	_set_next_scene(scene_id)
	ResourceLoader.load_threaded_request(next_scene)
	_enable()


func _set_next_scene(scene_id: int) -> void:
	next_scene = SceneManager.SCENES.get(scene_id, SceneManager.SCENES[SceneManager.scene_id.MAIN_MENU])
	%LoadingText.text = "Loading %s..." % SceneManager.scene_id.keys()[scene_id]


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


func _on_all_peers_ready() -> void:
	if not _wait_for_all_peers: return
	_disable()
