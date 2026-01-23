extends Node
## Utilities provide useful methods for common use

enum stage_id {
	PLAYGROUND
}

const STAGES: Dictionary = {
	stage_id.PLAYGROUND: preload("uid://dvi7lqoafi1cl")
}

# ----- Utilities -----

## Returns a player [Node] from [param peer_id]. 
## If the player is not found returns [code]null[/code]
## [br]Assumes that the player is inside [i]Players[/i] group.
func get_player_by_peer_id(peer_id: int) -> Node:
	for player in get_tree().get_nodes_in_group("Players"):
		if player.get_multiplayer_authority() == peer_id:
			return player
	
	return null


## Returns a random hex color value
func get_random_hex_color() -> String:
	var chars: String = "ABCDEF0123456789"
	var value: String = "#"
	
	for i in 6:
		value += chars[randi_range(0,len(chars)-1)]
		
	return value
