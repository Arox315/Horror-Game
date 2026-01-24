class_name LoadingScreen
extends Control


var ready_clients: Dictionary = {}
var is_loading: bool = true
var progress: Array = []


#func _enter_tree() -> void:
	#ready_clients[multiplayer.multiplayer_peer.get_unique_id()] = false
	#for peer in multiplayer.get_peers():
		#ready_clients[peer] = false


func _ready() -> void:
	MultiplayerManager.set_client_not_ready(multiplayer.multiplayer_peer.get_unique_id())
	ResourceLoader.load_threaded_request(SceneManager.next_scene)
	

func _process(_delta: float) -> void:
	if is_loading:
		ResourceLoader.load_threaded_get_status(SceneManager.next_scene, progress)
		%LoadingProgress.text = str(roundi(progress[0]*100))+"%"
		
		if progress[0] == 1.0:
			var scene_to_load = ResourceLoader.load_threaded_get(SceneManager.next_scene)
			SceneManager.load_scene(scene_to_load)
			is_loading = false
			
			#if multiplayer.multiplayer_peer.get_unique_id() != 1:
				#await get_tree().create_timer(5).timeout
				#
			#MultiplayerManager.set_client_ready(multiplayer.multiplayer_peer.get_unique_id())
			#is_loading = false
	#else:
		#if not MultiplayerManager.all_clients_ready(): return
	#
		#var scene_to_load = ResourceLoader.load_threaded_get(SceneManager.next_scene)
		#SceneManager.load_scene(scene_to_load)


#@rpc("reliable", "any_peer", "call_local")
#func client_ready() -> void:
	#var peer_id: int = multiplayer.get_remote_sender_id()
	#ready_clients[peer_id] = true
#
#
#func all_clients_ready() -> bool:
	#for value in ready_clients.values():
		#if not value:
			#return false
	#return true
