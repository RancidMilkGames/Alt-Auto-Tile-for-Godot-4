@tool

extends TileMap


# Called when the node enters the scene tree for the first time.
func _ready():
	for tile in get_used_cells(0):
		var source = get_cell_atlas_coords(0, tile)
		if source.x < 3 and source.y < 3:
			set_cell(0, tile, 0, Vector2i(0, 0))
			


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
