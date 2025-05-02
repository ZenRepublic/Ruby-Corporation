extends Node2D
class_name MapManager

@export var map_width:int = 13
@export var map_height:int = 10

@export_category("Item Value Settings")
@export var total_item_value_curve:Curve
@export var floor_value_weights:Array[float]
@export var weight_randomize_factor:float = 0.5
var total_reward_value:int
var final_value_weights:Array[float]

@export_category("Tile Noise Settings")
@export var tile_noise:FastNoiseLite
@export var tile_depth_offset_curve:Curve
@export var tile_frequency_curve:Curve
var depth_offset:float

@export_category("Obstacle Noise Settings")
@export var obstacle_noise:FastNoiseLite
@export var obs_frequency_curve:Curve
@export var obs_threshold_curve:Curve

@export_category("Map Resources")
@export var floor_resources:Array[FloorData]
@export var floor_scn:PackedScene
@export var border_scn:PackedScene
@export var hover_indication_scn:PackedScene

var floors:Array[FloorGenerator]
var hover_indications:Dictionary
var map_boundaries:Rect2

var is_generated:bool=false
signal on_map_generated()

func _init():
	add_to_group("MapManager")

# Called when the node enters the scene tree for the first time.
func _ready():
	total_reward_value = total_item_value_curve.sample(randf_range(0.0,1.0))
	randomize_floor_value_weights()
	
	for i in range(floor_resources.size()):
		var floor_generator:FloorGenerator = floor_scn.instantiate()
		add_child(floor_generator)
		move_child(floor_generator,0)
		floor_generator.floor_data = floor_resources[i]
		var max_item_value:int = ceili(total_reward_value*final_value_weights[i])
		floor_generator.max_items_value = max_item_value
		floors.append(floor_generator)
		
	randomize_noise()
	
	for tile_floor in floors:
		tile_floor.generate_tiles(tile_floor.floor_data,tile_noise)
	
	#now all the tiles will have the colliders off. go through each grid position and activate topmost
	for x in map_width:
		for y in map_height:
			var topmost_tile:MineTile = get_topmost_active_tile_at_position(Vector2(x,y))
			topmost_tile.activate()
			
	generate_indications()
	calculate_map_boundaries()
	
	var border_generator:BorderGenerator = border_scn.instantiate()
	add_child(border_generator)
	border_generator.generate_borders(map_width,map_height)
	
	is_generated=true
	on_map_generated.emit()
	
func randomize_floor_value_weights() -> void:
	var new_weights:Array[float]
	var sum:float = 0.0
	
	for weight in floor_value_weights:
		if weight == 0.0:
			new_weights.append(0.0)
			continue
		var random_factor:float = randf_range(-weight_randomize_factor,weight_randomize_factor)
		var new_weight:float = max(weight+random_factor,0)
		new_weights.append(new_weight)
		sum += new_weight
	
	for i in range(new_weights.size()):
		if new_weights[i]>0.0:
			new_weights[i] = new_weights[i]/sum
	
	final_value_weights = new_weights
		
	
func randomize_noise() -> void:
	tile_noise.seed = randi_range(0,65000)
	tile_noise.frequency = tile_frequency_curve.sample(randf_range(0.0,1.0))
	#print("Tile frequency: ",tile_noise.frequency)
	depth_offset = tile_depth_offset_curve.sample(randf_range(0.0,1.0))
	#print("Depth: ",depth_offset)
	
	obstacle_noise.seed = randi_range(0,65000)
	obstacle_noise.frequency = obs_frequency_curve.sample(randf_range(0.0,1.0))
	#print("Obstacle frequency: ",obstacle_noise.frequency)


func get_center_position() -> Vector2:
	var sum_position = Vector2()
	for key in floors[0].tiles.keys():
		var tile:MineTile = floors[0].tiles[key]
		sum_position += tile.global_position
	return floor(sum_position / floors[0].tiles.size())
	
func generate_indications() -> void:
	var indications_parent:Node2D = Node2D.new()
	indications_parent.name = "Indications"
	add_child(indications_parent)
	
	for y in range(map_height):
		for x in range(map_width):
			var indication:HoverIndication = hover_indication_scn.instantiate()
			indications_parent.add_child(indication)
			hover_indications[Vector2(x,y)] = indication
			indication.setup(Vector2(x,y))
			

func calculate_map_boundaries() -> void:
#first, get min and max points for both x and y
	var min_x:int = 10000
	var max_x:int = 0
	var min_y:int = 10000
	var max_y:int = 0
	
	for cell in floors[0].tiles.keys():
		var tile:MineTile = floors[0].tiles[cell]
		
		if tile.global_position.x < min_x:
			min_x = floor(tile.global_position.x)
		if tile.global_position.x > max_x:
			max_x = floor(tile.global_position.x)
		
		if tile.global_position.y < min_y:
			min_y = floor(tile.global_position.y)
		if tile.global_position.y > max_y:
			max_y = floor(tile.global_position.y)
			
	map_boundaries = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))
	
func get_map_boundaries() -> Rect2:
	return map_boundaries
	
func is_in_bounds(grid_position:Vector2) -> bool:
	return grid_position.x >= 0 && grid_position.x < map_width && grid_position.y >= 0 && grid_position.y < map_height
	
func apply_depth_offset(noise_value:float) -> float:
	noise_value = 1-noise_value
	return clamp(noise_value-depth_offset,0.0,1.0)
	
func get_noise_value(noise:FastNoiseLite,point:Vector2) -> float:
	var noise_value:float = noise.get_noise_2d(point.x,point.y)
	#at this point, noise value will range from -1 to 1, so we gotta remap it
	noise_value = (noise_value+1.0) / 2.0
	noise_value = clamp(noise_value,0.0,1.0)
	return noise_value

func get_noise_strength(noise_value:float, use_tile_layers:bool=false) -> int:
	var total_layers:int = 0
	
	if !use_tile_layers:
		total_layers = floors.size()
	else:
		for tile_floor in floors:
			total_layers += tile_floor.floor_data.layers.size()
			
	var noise_threshold = 1.0 / total_layers
	
	var noise_strength:int = 0
	for i in range(total_layers-1):
		if noise_value > (i+1)*noise_threshold:
			noise_strength += 1

	return noise_strength
	
func get_tile_layer_depth(floor_level:int,layer_id:int)->int:
	var layer_depth:int=0
	for i in range(floors.size()):
		for j in range(floors[i].floor_data.layers.size()):
			if i == floor_level && j == layer_id:
				break
			layer_depth += 1
			
		if i == floor_level:
			break
	
	return layer_depth
	
#go layer by layer to find the first active tile
func get_topmost_active_tile_at_position(pos_in_grid:Vector2) -> MineTile:
	for tile_floor in floors:
		var tile:MineTile = tile_floor.get_tile_by_pos(pos_in_grid)
		if tile == null:
			continue
		if !tile.destroyed:
			return tile
			
	return null
	
func get_surrounding_area(pos:Vector2,radius:float) -> Array[MineTile]:
	var tiles_in_area:Array[MineTile]
	# Loop through each tile in the grid
	for x in range(map_width):
		for y in range(map_height):
			var distance:float = sqrt(pow(x - pos.x, 2) + pow(y - pos.y, 2))
			if distance <= radius:
				var tile_in_radius:MineTile = get_topmost_active_tile_at_position(Vector2(x,y))
				tiles_in_area.append(tile_in_radius)
	return tiles_in_area
	
func get_tile_on_floor(floor_level:int,pos_in_grid:Vector2) -> MineTile:
	var floor_generator:FloorGenerator
	
	for tile_floor in floors:
		if tile_floor.floor_data.floor_level == floor_level:
			floor_generator = tile_floor
			
	if floor_generator == null:
		push_error("COULDNT FIND TILE ON FLOOR!")
		return
	
	return floor_generator.get_tile_by_pos(pos_in_grid)
	
func get_treasures_remaining() -> int:
	var treasures_remaining:int=0
	for tile_floor in floors:
		var floor_treasures:Array = tile_floor.item_generator.get_active_items_of_type(MineItem.ItemType.TREASURE)
		treasures_remaining += floor_treasures.size()
	return treasures_remaining
