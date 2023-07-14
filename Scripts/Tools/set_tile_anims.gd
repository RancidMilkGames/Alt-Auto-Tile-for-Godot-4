@tool

extends TileMap

var start_tile: Vector2i = Vector2i(3, 10)
var end_tile: Vector2i = Vector2i(26, 13)


# Called when the node enters the scene tree for the first time.
func _ready():
	var atlas = tile_set.get_source(0) as TileSetAtlasSource
	
	for y in (end_tile.y - start_tile.y) + 1:
		for x in (end_tile.x - start_tile.x) + 1:
			
#			if x <= 3:
#				continue
#
			var cur_tile = Vector2i(x + start_tile.x, y + start_tile.y)
#			atlas.set_tile_animation_frames_count(cur_tile, 0)
#			atlas.set_tile_animation_columns(cur_tile, 1)
#			atlas.set_tile_animation_separation(cur_tile, Vector2i(0, 2))
#			atlas.set_tile_animation_frames_count(cur_tile, 4)
			for i in atlas.get_tile_animation_frames_count(cur_tile):
				atlas.set_tile_animation_frame_duration(cur_tile, i, .1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
