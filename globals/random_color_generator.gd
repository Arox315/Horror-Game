extends Node

var rng = RandomNumberGenerator.new()

## Returns random hex value
func rand_hex() -> String:
	var chars: String = "ABCDEF0123456789"
	var value: String = "#"
	
	for i in 6:
		value += chars[rng.randi_range(0,len(chars)-1)]
		
	return value
