extends Node

## Emitted when generated
signal generated

## TileMap Reference
@onready var t_map: TileMap = get_parent()
## Tileset that TileMaps should share
@onready var t_set: TileSet = t_map.tile_set

## Rows to generate
@export var rows: int = 31
## Columns to generate
@export var columns: int = 32

## Whether the tiles are weighted by the example tilemap
@export var weighted: bool = false
## Whether to use Tile Probability values or not
@export var use_probability: bool = true
## Max attempts to match a tile before giving up
@export var max_match_attempts: int = 100

## Output TileMap
var output: TileMap

@export_category("Debug")

## Generate as fast as possible, or slow it down to watch
@export var delayed: bool = false
## How many steps between displaying progress updates
@export var delay_interval: int = 100
## Whether to generate tiles or not
@export var enabled: bool = true

## An array containing all the TileMap coords we will fill
var to_tile: Array[Vector2i] = []
## An array that keeps track of troublesome areas
var stuck_tiles: Array[Vector2i] = []


func _ready():
	# Make the ref TileMap invisible
	t_map.visible = false
	# Make the output TileMap
	output = TileMap.new()
	# Set its TileSet
	output.tile_set = t_map.tile_set
	# Add layer for trees
	output.add_layer(-1)
	# Add to scene
	t_map.get_parent().add_child.call_deferred(output)
	# Set background color to grass color
	RenderingServer.set_default_clear_color(Color.from_string("#85a643", Color.AQUAMARINE))

	# If not enabled, stop
	if not enabled:
		return
	
	analyze_tiles()
	await generate_tiles()
	generated.emit()
	
	
	
func analyze_tiles():
	# Get the data layer for our custom resource
	var data_layer = t_set.get_custom_data_layer_by_name("super_tile")
	# Check if it exists
	if data_layer == -1:
		# If it doesn't, create a new data layer
		t_set.add_custom_data_layer()
		# Name it super_tile
		t_set.set_custom_data_layer_name(t_set.get_custom_data_layers_count() - 1, "super_tile")
	
	# Get all used cells
	for cell in t_map.get_used_cells(0):
		# We'll need a SuperTileResource to keep the surrounding tile data in
		var super_tile_resource: SuperTileResource
		# Get the atlas coords of each cell
		var atlas_coords = t_map.get_cell_atlas_coords(0, cell)
		# Get our custom data if the tile already has it
		var t_data = t_set.get_source(0).get_tile_data(atlas_coords, 0).get_custom_data("super_tile")

		# Check if it already has the custom resource, or if we need to make one
		if t_data:
			super_tile_resource = t_data
		else:
			super_tile_resource = SuperTileResource.new()
		
#		super_tile_resource.my_atlas_coords = atlas_coords
		
		# Save surrounding cells for 0 (Top Left)
		save_surr_cells(super_tile_resource, cell, Vector2i(-1, -1), 0)
		# Save surrounding cells for 1 (Top)
		save_surr_cells(super_tile_resource, cell, Vector2i(0, -1), 1)
		# Save surrounding cells for 2 (Top Right)
		save_surr_cells(super_tile_resource, cell, Vector2i(1, -1), 2)
		# Save surrounding cells for 3 (Right)
		save_surr_cells(super_tile_resource, cell, Vector2i(1, 0), 3)
		# Save surrounding cells for 4 (Bottom Right)
		save_surr_cells(super_tile_resource, cell, Vector2i(1, 1), 4)
		# Save surrounding cells for 5 (Bottom)
		save_surr_cells(super_tile_resource, cell, Vector2i(0, 1), 5)
		# Save surrounding cells for 6 (Bottom Left)
		save_surr_cells(super_tile_resource, cell, Vector2i(-1, 1), 6)
		# Save surrounding cells for 7 (Left)
		save_surr_cells(super_tile_resource, cell, Vector2i(-1, 0), 7)
		
		# Save the new/updated data to the tile
		t_set.get_source(0).get_tile_data(atlas_coords, 0).set_custom_data("super_tile", super_tile_resource)


func generate_tiles():
	# Start the first cell with our main TileSet tile(Grass middle)
	output.set_cell(0, Vector2i(0, 0), 0, Vector2i(0, 0))
	# Add all rows and columns to the to_tile array
	for c in columns:
		for r in rows:
			to_tile.append(Vector2i(r, c))

	# Save the last tile for checking if things get stuck
	var last_tile
	# Will only count up. Keeps track of the current row
	var last_row = -1
	# Steps between delays if delay is on
	var delay_counter = 0
	# While we still have places to put tiles, keep placing them
	while to_tile.size() > 0:
		# When a new row has started
		if to_tile[0].y != last_row:
			# Update row we're on
			last_row = to_tile[0].y
			# Get the first tile of the previous row
			var atlas_coords = output.get_cell_atlas_coords(0, Vector2i(0, last_row))
			# Get the atlas source
			var atlas_source = t_set.get_source(0) as TileSetAtlasSource
			# Get our custom data from the tile
			var t_data = atlas_source.get_tile_data(atlas_coords, 0).get_custom_data("super_tile")

			# If the tile has data for what tiles can go below it
			if t_data.surrounding[5].size() > 0:
				# Set the new cell to one of the possibilities
				if use_probability:
					output.set_cell(0, Vector2i(0, last_row + 1), 0, get_tile_w_prob(t_data, 5))
				else:
					output.set_cell(0, Vector2i(0, last_row + 1), 0, t_data.surrounding[5].pick_random())
			else:
				# If it doesn't, we just add the main grass tile
				# Note: the auto-tile won't work well, if at all, if this code line is being used.
				output.set_cell(0, Vector2i(0, last_row + 1), 0, Vector2i.ZERO)
		
		# If we failed to place the last tile
		if to_tile[0] == last_tile:
			# Add the one left of it to the front of our to_tile array
			to_tile.push_front(to_tile[0] + Vector2i.LEFT)
		# Set the last tile so it's ready for the next check
		last_tile = to_tile[0]
		# Try to actually place the tile
		await try_place(to_tile[0])
		# If delay is enabled(We want to watch generation)
		if delayed:
			# If delay steps have been reached
			if delay_counter >= delay_interval:
				# Reset counter
				delay_counter = 0
				# await the shortest duration we can
				await get_tree().process_frame
			else:
				# Add one to the counter
				delay_counter += 1
	
	# add trees with post gen
	post_gen()
	
func post_gen():
	# Get all used tiles in our ourput TileMap
	for tile in output.get_used_cells(0):
		# If it can have a tree over it
		if output.get_cell_atlas_coords(0, tile) == Vector2i(0, 0):
			var x = randi_range(0, 2)
			var y = randi_range(0, 2)
			output.set_cell(0, tile, 0, Vector2i(x, y))
			
			# Random 50% chance it gets a tree
			if randi_range(0, 3) == 0:
				# Tree goes in the layer above the grass
				output.set_cell(1, tile, 0, Vector2i(8, 7))


## Function that attempts to place a tile
func try_place(map_coords, attempt = 0):
	# Get the atlas coords of the current tile
	var atlas_coords = output.get_cell_atlas_coords(0, map_coords)
	# Get the source from the TileSet
	var atlas_source = t_set.get_source(0) as TileSetAtlasSource
	
	# This catch shouldn't be needed in future versions
	# If the tile is invalid for any reason though,
	# we want to remove the bad tile
	if atlas_coords == Vector2i(-1, -1):
		var count = 0
		for t in to_tile:
			if t == map_coords:
				# Remove bad tile
				to_tile.remove_at(count)
				break
			count += 1
		return
	
	# Get the tile data
	var t_data = atlas_source.get_tile_data(atlas_coords, 0)
	# var for custom tile data
	var cust_data = t_data.get_custom_data("super_tile")
	
	# Check if data contains tiles that can go on the right
	if cust_data.surrounding[3].size() > 0:
		if use_probability:
			output.set_cell(0, map_coords + Vector2i.RIGHT, 0, get_tile_w_prob(cust_data, 3))
		else:
			output.set_cell(0, map_coords + Vector2i.RIGHT, 0, cust_data.surrounding[3].pick_random())
	else:
		# Else, we default to the main grass tile. We shouldn't need this code though
		output.set_cell(0, map_coords + Vector2i.RIGHT, 0, Vector2i.ZERO)
	
	# Check that the new tile fits
	await check_place(map_coords, map_coords + Vector2i.RIGHT, attempt)


func check_place(prev_coords, testing_coords, attempt):
	# Get the atlas info and data
	var atlas_coords = output.get_cell_atlas_coords(0, testing_coords)
	var atlas_source = t_set.get_source(0) as TileSetAtlasSource
	var t_data = atlas_source.get_tile_data(atlas_coords, 0)
	var cust_data = t_data.get_custom_data("super_tile")
	
	# Get the tile above's coords
	var above_tile_atlas = output.get_cell_atlas_coords(0, testing_coords + Vector2i(0, -1))
	if above_tile_atlas == Vector2i(-1, -1):
		to_tile.remove_at(0)
		return
	
	# Iterate through all possible tiles that can go above this one
	for t_coord in cust_data.surrounding[1]:
		# If the above tile is in the matching tiles of what can go above this tile
		if t_coord == above_tile_atlas:
			# We can remove the tile and end the function early, because it fits.
			to_tile.remove_at(0)
			return
	
	# Didn't find the tile:
	# Check if attempt number is == to max attempts
	if attempt >= max_match_attempts:
			# If it is, we redo all tiles from the top left of this one
			roll_back_row(prev_coords)
	else:
		# add one to the attempt count and try again
		attempt += 1
		await try_place(prev_coords, attempt)
		
func roll_back_row(coords):
	# Add the stuck tile to our array
	stuck_tiles.append(coords)

	# Count for times a tile is stuck
	var tile_match_count = 0
	for st in stuck_tiles:
		if st == coords:
			tile_match_count += 1
		
		# If the same coords have been stuck more than 5 times
		if tile_match_count >= 5:
			# TODO: This needs refactored:
			
			# We want to put all tiles to the left, back into to_tile
			var inv_append = []
			for i in coords.x:
				inv_append.push_front(Vector2i(i, coords.y))
			for inv in inv_append:
				to_tile.push_front(inv)

			# We also want to put all the tiles from the top right of this one back
			var to_add_tiles = []
			var current_tile_x
			for i in range(coords.x - 1, rows):
				to_add_tiles.push_front(Vector2i(i, coords.y - 1))
			to_add_tiles.push_front(coords + Vector2i.LEFT)
			for tad in to_add_tiles:
				to_tile.push_front(tad)
			
			# Reset stuck tiles
			stuck_tiles = []
			break

func save_surr_cells(cell_resource: SuperTileResource, cell, offset, cell_key):
	var surr_cell = t_map.get_cell_atlas_coords(0, cell + offset)
	if surr_cell and surr_cell != Vector2i(-1, -1):
		# We don't want to add the vectors more than once if it's unweighted
		if not weighted:
			for c_key in cell_resource.surrounding[cell_key]:
				if c_key == surr_cell:
					return
		cell_resource.surrounding[cell_key].append(surr_cell)
		

func _input(event):
	# Press space to re-run everything
	if event.is_action_pressed("jump"):
		to_tile = []
		for c in columns:
			for r in rows:
				output.erase_cell(0, Vector2i(r, c))
				output.erase_cell(1, Vector2i(r, c))
		await get_tree().physics_frame
		await generate_tiles()

## This function gets a surrounding tile based on probability 
func get_tile_w_prob(tile: SuperTileResource, direction: int):
	# TODO: Generate the total prob for each tile on Tiler start instead of each time
	
	# We want to add up all the probabilities, so we can get a rand num in range
	var total_prob = 0
	for t in tile.surrounding[direction]:
		var t_data = (t_set.get_source(0) as TileSetAtlasSource).get_tile_data(t, 0)
		var cust_data = t_data.get_custom_data("super_tile")
		total_prob += cust_data.probability
	
	# Choose a rand point in the range
	var chosen = randf_range(0, total_prob)
	for t in tile.surrounding[direction]:
		var t_data = (t_set.get_source(0) as TileSetAtlasSource).get_tile_data(t, 0)
		var cust_data = t_data.get_custom_data("super_tile")
		chosen -= cust_data.probability
		# Once we've hit 0 or less, we know we have the tile we want
		if chosen <= 0:
			return t
