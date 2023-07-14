extends Resource

class_name SuperTileResource

var my_atlas_coords: Vector2i

@export var surrounding: Dictionary = {
	0: [],
	1: [],
	2: [],
	3: [],
	4: [],
	5: [],
	6: [],
	7: [],
}

@export var probability: float = 1.0

func get_name():
	return "SuperTileResource"
	
