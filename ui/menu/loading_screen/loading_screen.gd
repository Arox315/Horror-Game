class_name LoadingScreen
extends CanvasLayer

var ready_clients: Dictionary = {}
var is_loading: bool = true
var progress: Array = []
var next_scene: String
var _wait_for_all_peers: bool = true
var connected_to_server: bool = false
var server_scene_received: bool = false
var fallback_timer: Timer = Timer.new()


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	MultiplayerManager.all_peers_ready.connect(_on_all_peers_ready)
	MultiplayerManager.server_scene_received.connect(_on_server_scene_received)
	
	fallback_timer.autostart = false
	fallback_timer.one_shot = true
	fallback_timer.wait_time = 10.0
	fallback_timer.timeout.connect(_on_fallback_timer_timeout)
	add_child(fallback_timer)
	
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
			%LoadingProgress.text = ""
		
		if not _wait_for_all_peers:
			_disable()
			return
		
		_send_status_ready()


func start_loading_new_scene(scene_id: int, wait_for_all_peers: bool = true) -> void:
	_send_status_not_ready()
	_send_status_not_loaded()
	_wait_for_all_peers = wait_for_all_peers
	
	await get_tree().physics_frame
	
	_set_next_scene(scene_id)
	ResourceLoader.load_threaded_request(next_scene)
	_enable()


func start_connecting_to_server() -> void:
	connected_to_server = false
	server_scene_received = false
	show()
	fallback_timer.start()
	%LoadingText.text = "Connecting to the server..."
	%LoadingProgress.text = ""


func _start_loading_scene_on_connected() -> void:
	if not connected_to_server: return
	if not server_scene_received: return
	start_loading_new_scene(MultiplayerManager.server_current_scene_id, false)
	print_debug("server_scene = ", MultiplayerManager.server_current_scene_id)


func _on_connected_to_server() -> void:
	connected_to_server = true
	fallback_timer.stop()
	_start_loading_scene_on_connected()


func _on_server_scene_received() -> void:
	server_scene_received = true
	_start_loading_scene_on_connected()


func _set_next_scene(scene_id: int) -> void:
	next_scene = SceneManager.SCENES.get(scene_id, SceneManager.SCENES[SceneManager.scene_id.MAIN_MENU])
	%LoadingText.text = "Loading %s..." % SceneManager.scene_id.keys()[scene_id]
	print("[%s] Loading %s..." % [self, SceneManager.scene_id.keys()[scene_id]])


func _load_scene(scene_to_load: PackedScene) -> void:
	if MultiplayerManager.is_valid_multiplayer_connection():
		owner.disable_synchronizers.rpc()
	
	var previous_scene: Node = owner.main_scene
	if previous_scene: 
		for child in previous_scene.get_children():
			child.queue_free()
		previous_scene.call_deferred("queue_free")
	
	await get_tree().physics_frame
	
	var new_scene = scene_to_load.instantiate()
	owner.add_child(new_scene)
	owner.main_scene = new_scene
	
	await get_tree().physics_frame
	_send_status_loaded()


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


func _send_status_loaded() -> void:
	if not MultiplayerManager.is_valid_multiplayer_connection(): return
	
	if multiplayer.is_server():
		MultiplayerManager.client_loaded()
	else:
		print("[%s] Client %s sending loaded..." % [self, multiplayer.multiplayer_peer.get_unique_id()])
		MultiplayerManager.client_loaded.rpc_id(1)


func _send_status_ready() -> void:
	if not MultiplayerManager.is_valid_multiplayer_connection(): return
		
	if multiplayer.is_server():
		MultiplayerManager.client_ready()
	else:
		print("[%s] Client %s sending ready..." % [self, multiplayer.multiplayer_peer.get_unique_id()])
		MultiplayerManager.client_ready.rpc_id(1)


func _send_status_not_ready() -> void:
	if not MultiplayerManager.is_valid_multiplayer_connection(): return
		
	if multiplayer.is_server():
		MultiplayerManager.set_clinet_not_ready()
	else:
		MultiplayerManager.set_clinet_not_ready.rpc_id(1)


func _send_status_not_loaded() -> void:
	if not MultiplayerManager.is_valid_multiplayer_connection(): return
	
	if multiplayer.is_server():
		MultiplayerManager.set_clinet_not_loaded()
	else:
		MultiplayerManager.set_clinet_not_loaded.rpc_id(1)


func _on_fallback_timer_timeout() -> void:
	print("[%s] Unable to connect to the server." % self)
	MultiplayerManager.terminate_connection()
	_disable()
