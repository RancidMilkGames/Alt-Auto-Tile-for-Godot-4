@tool

extends Node

## Helps copy surrounding tile data from one tile to another
##
## Description
##

@onready var t_map: TileMap = get_parent()
@onready var t_set: TileSet = t_map.tile_set

## Tile to copy surrounding tiles to
@export var target_tile: Vector2i = Vector2i(-1, -1)
## Tile to copy surrounding tiles from
@export var ref_tile: Vector2i = Vector2i(-1, -1)
## Direction to copy surrounding tiles from
## 0-7. 0 is top left, 1 is above, 2 is is top right, 3 is right, etc.
@export var direction_as_int: int = -1
## SuperTileResource for tile. Only needed if not already on tile.
@export var super_tile_resource: SuperTileResource
## Click this bool to run the code
@export var run_code: bool = false:
	set(r):
		run_code = false
		run_single()

@export_category("Array tool")

@export var run_code_arrays: bool = false:
	set(r):
		run_code_arrays = false
		run_arrays()
		
@export var target_arrays: Array[Vector2i] = []

func run_single():
	var atlas_source = t_set.get_source(0) as TileSetAtlasSource
	var ref_t_data = atlas_source.get_tile_data(ref_tile, 0)
	var ref_cust_data = ref_t_data.get_custom_data("super_tile") as SuperTileResource
	
	if not ref_t_data or not ref_cust_data:
		push_error("Reference tile has no SuperTileResource!")
		return
		
	var target_atlas_source = t_set.get_source(0) as TileSetAtlasSource
	var target_t_data = target_atlas_source.get_tile_data(target_tile, 0)
	
	for ref_t in ref_cust_data.surrounding[direction_as_int]:
		var found = false
		for target_t in super_tile_resource.surrounding[direction_as_int]:
			if target_t == ref_t:
				found = true
		if not found:
			super_tile_resource.surrounding[direction_as_int].append(ref_t)
	
	super_tile_resource.set("surrounding", super_tile_resource.surrounding)
	target_t_data.set_custom_data("super_tile", super_tile_resource)


func run_arrays():
	var atlas_source = t_set.get_source(0) as TileSetAtlasSource
	var ref_t_data = atlas_source.get_tile_data(ref_tile, 0)
	var ref_cust_data = ref_t_data.get_custom_data("super_tile") as SuperTileResource
	
	if not ref_t_data or not ref_cust_data:
		push_error("Reference tile has no SuperTileResource!")
		return
		
	var target_atlas_source = t_set.get_source(0) as TileSetAtlasSource
	
	for ta in target_arrays:
		var target_t_data = target_atlas_source.get_tile_data(ta, 0)

		var target_cust_data = target_t_data.get_custom_data("super_tile") as SuperTileResource
	
		for ref_t in ref_cust_data.surrounding[direction_as_int]:
			var found = false
			for target_t in target_cust_data.surrounding[direction_as_int]:
				if target_t == ref_t:
					found = true
			if not found:
				target_cust_data.surrounding[direction_as_int].append(ref_t)
	
		target_cust_data.set("surrounding", target_cust_data.surrounding)
		target_t_data.set_custom_data("super_tile", target_cust_data)


# TODO:
#func convert_tiles():
#	var new_tile_map = get_parent().get_parent().get_node("TileMap")
#	var atlas_source = t_set.get_source(0) as TileSetAtlasSource
#	var coords = []
#	for i in atlas_source.get_tiles_count():
#		coords.append(atlas_source.get_tile_id(i))
#
#	for c in coords:
#		var tile = atlas_source.get_tile_data(c, 0)
#		var cust = tile.get_custom_data("super_tile") as SuperTileResource
#
#		for surr in cust.surrounding:
#			for s in surr:
#				pass
#		var info = NewSuperTileResource.TileInfo.new()
##		info.
		
		
