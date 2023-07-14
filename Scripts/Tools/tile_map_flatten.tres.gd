@tool

extends Node2D

@export var target_tm: TileMap

@export var tm1: TileMap

@export var tm2: TileMap


# Called when the node enters the scene tree for the first time.
func _ready():
	for c in tm1.get_used_cells(0):
		var atlas_coords = tm1.get_cell_atlas_coords(0, c)
		target_tm.set_cell(1, c, 0, atlas_coords)
		
	for c in tm2.get_used_cells(0):
		var atlas_coords = tm2.get_cell_atlas_coords(0, c)
		target_tm.set_cell(2, c, 0, atlas_coords)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
