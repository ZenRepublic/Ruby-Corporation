extends Node2D
class_name FloorGenerator

@export var tile_scn:PackedScene
@onready var item_generator:ItemGenerator = $ItemGenerator

var tiles:Dictionary

var map_boundaries:Rect2
var map_manager:MapManager

var floor_data:FloorData
var max_items_value:int
	
# Called when the node enters the scene tree for the first time.
func _ready():
	map_manager = get_parent()


func generate_tiles(data:FloorData,noise:FastNoiseLite) -> void:
	floor_data = data
	
	var tiles_parent:Node2D = Node2D.new()
	tiles_parent.name = "Tiles"
	add_child(tiles_parent)
	
	for y in range(map_manager.map_height):
		for x in range(map_manager.map_width):
			var tile:MineTile = tile_scn.instantiate()
			tiles_parent.add_child(tile)
			tiles[Vector2(x,y)] = tile
			
			var noise_value:float = map_manager.get_noise_value(noise,Vector2(x,y))
			noise_value = map_manager.apply_depth_offset(noise_value)
			tile.setup(Vector2(x,y),map_manager.get_noise_strength(noise_value,true),self)
			tile.on_destroyed.connect(activate_next_floor_tile)
			
	if floor_data.possible_obstacles.keys().size() >0:
		item_generator.spawn_obstacles(floor_data.possible_obstacles)
	if floor_data.possible_treasures.keys().size() > 0:
		item_generator.spawn_items(floor_data.possible_treasures,max_items_value)
	if floor_data.possible_utilities.keys().size() > 0:
		item_generator.spawn_utility(floor_data.possible_utilities,floor_data.utility_spawn_density)	
	
func get_tile_by_pos(grid_pos:Vector2) -> MineTile:
	if !is_in_bounds(grid_pos):
		return null
	for tile in tiles.keys():
		if tile == grid_pos:
			#if tiles[tile].destroyed:
				#return null
			return tiles[tile]
	return null
	
func get_depth() -> int:
	return floor_data.floor_level
	
func get_global_layer_depth(layer_id:int) -> int:
	return map_manager.get_tile_layer_depth(floor_data.floor_level,layer_id)
	
func is_in_bounds(pos:Vector2) -> bool:
	var size:Vector2 = Vector2(map_manager.map_width,map_manager.map_height)
	return pos.x >= 0 and pos.y >= 0 and pos.x < size.x and pos.y < size.y
	
	
func activate_next_floor_tile(destroyed_tile:MineTile) -> void:
	var next_tile:MineTile = map_manager.get_tile_on_floor(floor_data.floor_level+1,destroyed_tile.pos_in_grid)
	if next_tile!=null:
		next_tile.activate()
	
func can_be_hit(tile:MineTile) -> bool:
	if !floor_data.is_destroyable:
		return false
		
	#can always hit the first floor
	if floor_data.floor_level == 0:
		return true
		
	var tile_above:MineTile = map_manager.floors[floor_data.floor_level-1].get_tile_by_pos(tile.pos_in_grid)
	#can be hit if there's no tile above it and if there's no treasure hidden under the above tile
	if tile_above.destroyed && tile_above.occupied_by==null:
		return true
	else:
		return false
		
#returns percentage of how many tiles are not destroyed on the floor based on map size
func get_tile_density() -> float:
	var active_tile_count:int = 0
	for key in tiles.keys():
		var tile:MineTile = tiles[key]
		if !tile.destroyed:
			active_tile_count+=1
	
	return ceil(float(active_tile_count)/tiles.keys().size())
	
func get_active_tiles() -> Dictionary:
	var active_tiles:Dictionary
	for key in tiles.keys():
		var tile:MineTile = tiles[key]
		if !tile.destroyed:
			active_tiles[key] = tile
	return active_tiles
				
func get_random_tile(active_only:bool=true) -> MineTile:
	var random_tiles:Dictionary
	if active_only:
		random_tiles = get_active_tiles()
	else:
		random_tiles = tiles
		
	var rand_id:int = randi_range(0,random_tiles.size()-1)
	
#	corner case no fking clue why the tile would be unavailable
	if !random_tiles.has(random_tiles.keys()[rand_id]):
		return null
		
	return random_tiles[random_tiles.keys()[rand_id]]
