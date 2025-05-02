extends Node2D
class_name ItemGenerator

var MAX_SPAWN_ATTEMPTS:int = 100

var spawned_obstacles:Array[MineItem]
var spawned_items:Array[MineItem]

var floor_generator:FloorGenerator

func _ready():
	floor_generator = get_parent()
	
func spawn_obstacles(possible_obstacles:Dictionary) -> void:
	var obstacles_parent:Node2D = Node2D.new()
	obstacles_parent.name = "Obstacles"
	add_child(obstacles_parent)
	
	var map_manager:MapManager = get_tree().get_first_node_in_group("MapManager")
	var tiles:Dictionary = floor_generator.get_active_tiles() 
	for key in tiles.keys():	
		var tile:MineTile = tiles[key]
		
		var noise_value:float = map_manager.get_noise_value(map_manager.obstacle_noise,tile.pos_in_grid)
		#make the noise bloby by applying a threshold
		#var orig_noise:float = noise_value
		noise_value = map_manager.obs_threshold_curve.sample(noise_value)
		if noise_value == 0:
			continue

		var noise_strength:int = map_manager.get_noise_strength(noise_value)
		#print(orig_noise, " ",noise_value, " ",noise_strength)
		if floor_generator.floor_data.floor_level >= noise_strength:
			var obstacle_resource:ItemResource = select_random_item(possible_obstacles)
			var obstacle_instance:MineItem = spawn(obstacle_resource.scene,[tile],obstacles_parent)
			spawned_obstacles.append(obstacle_instance)
	#print(spawned_obstacles.size())


func spawn_utility(possible_items:Dictionary,spawn_density:int) -> void:
	var items_parent:Node2D = Node2D.new()
	items_parent.name = "Utility"
	add_child(items_parent)
	
	var spawn_amount:int = calculate_spawn_amount(floor_generator.get_tile_density(),spawn_density)
	
	for i in range(spawn_amount):
		var item_resource:ItemResource = select_random_item(possible_items)
		for j in range(MAX_SPAWN_ATTEMPTS):
			var random_tile:MineTile = floor_generator.get_random_tile()
			if random_tile==null:
				continue
			#all tiles have got to be free
			var tiles_to_occupy:Array[MineTile] = get_tiles_to_occupy(item_resource.dimensions,random_tile)
			if tiles_to_occupy.size()==0:
				continue
			
			if !can_place_on_tiles(tiles_to_occupy):
				continue
			
			var item_instance:MineItem = spawn(item_resource.scene,tiles_to_occupy,items_parent)
			spawned_items.append(item_instance)
			break
			
func spawn_items(possible_items:Dictionary,max_value:int) -> void:
	var items_parent:Node2D = Node2D.new()
	items_parent.name = "Items"
	add_child(items_parent)
	
	var remaining_budget:int = ceili(max_value*floor_generator.get_tile_density())
	
	while remaining_budget > 0:
		var affordable_items:Dictionary = filter_affordable_items(possible_items,remaining_budget)
		if affordable_items.size() == 0:
			remaining_budget = 0
			break
			
		var item_resource:ItemResource = select_random_item(affordable_items)
		for i in range(MAX_SPAWN_ATTEMPTS):
			var random_tile:MineTile = floor_generator.get_random_tile()
			if random_tile==null:
				continue
			#all tiles have got to be free
			var tiles_to_occupy:Array[MineTile] = get_tiles_to_occupy(item_resource.dimensions,random_tile)
			if tiles_to_occupy.size()==0:
				continue
			
			if !can_place_on_tiles(tiles_to_occupy):
				continue
			
			var item_instance:MineItem = spawn(item_resource.scene,tiles_to_occupy,items_parent)
			spawned_items.append(item_instance)
			break
		
		remaining_budget -= item_resource.weight
	
	
func spawn(item_scn:PackedScene,tiles_to_occupy:Array[MineTile],custom_parent:Node2D=null) -> MineItem:
	var item_instance:MineItem = item_scn.instantiate()
	
	if custom_parent!=null:
		custom_parent.add_child(item_instance)
	else:
		add_child(item_instance)
		
	if tiles_to_occupy.size() == 1:
		item_instance.global_position = tiles_to_occupy[0].global_position
	else:
		item_instance.global_position = get_spawn_position(tiles_to_occupy)
		
	item_instance.set_occupied_tiles(tiles_to_occupy)
	item_instance.on_uncover_finished.connect(remove_item,CONNECT_ONE_SHOT)
	return item_instance
		
func filter_affordable_items(possible_items:Dictionary,remaining_budget:int) -> Dictionary:
	var affordable_items:Dictionary
	for item in possible_items.keys():
		var item_resource:ItemResource = item as ItemResource
		if item_resource.weight <= remaining_budget:
			affordable_items[item] = possible_items[item]
	return affordable_items
	
			
func select_random_item(possible_items:Dictionary) -> ItemResource:
	var total_weight = 0
	for resource in possible_items.keys():
		total_weight += possible_items[resource]
		
	var random_value:int = randi_range(0,total_weight)
	var cumulative_weight:int = 0
	for resource in possible_items.keys():
		cumulative_weight += possible_items[resource]
		if random_value <= cumulative_weight:
			return resource

	push_error("COULDNT SELECT ITEM")
	return null
	
func calculate_spawn_amount(tile_density:float,spawn_density:int) -> int:
	var spawn_amount:int = ceil(lerp(0,spawn_density,tile_density))
	var random_offset:int = 1

	var min_spawn:int = clamp(spawn_amount-random_offset,0,INF)
	var max_spawn:int = clamp(spawn_amount+random_offset,0,INF)
	var final_spawn_amount:int = randi_range(min_spawn,max_spawn)
	
	return final_spawn_amount
	
func can_place_on_tiles(tiles_to_occupy:Array[MineTile]) -> bool:
	for tile in tiles_to_occupy:
		if tile.occupied_by != null:
			return false
	
	return true
	
func get_tiles_to_occupy(item_size:Vector2, starting_tile:MineTile) -> Array[MineTile]:
	var tiles_to_occupy:Array[MineTile]
	for i in range(item_size.x):
		for j in range(item_size.y):
			var tile_pos:Vector2 = Vector2(starting_tile.pos_in_grid.x+i,starting_tile.pos_in_grid.y+j)
			
			if !floor_generator.tiles.has(tile_pos):
				#item needs to fully fit into the map, if not, return null and dont check any more
				return []
				
			var tile:MineTile = floor_generator.tiles[tile_pos]
			if tile.destroyed:
				#item also needs to be fully covered by tiles
				return []
				
			tiles_to_occupy.append(tile)
			
	return tiles_to_occupy

func get_spawn_position(tile_points:Array[MineTile]) -> Vector2:
	var accumulated_point:Vector2=Vector2.ZERO
	for point in tile_points:
		accumulated_point += point.global_position
		
	return accumulated_point/tile_points.size()
	
func get_occupied_tiles() -> Array[MineTile]:
	var occupied_tiles:Array[MineTile]
	for item in spawned_items:
		for tile in item.occupied_tiles:
			occupied_tiles.append(tile)
	for item in spawned_obstacles:
		for tile in item.occupied_tiles:
			occupied_tiles.append(tile)
	return occupied_tiles
	
func remove_item(item:MineItem) -> void:
	var item_index:int = spawned_items.find(item)
	if item_index!=-1:
		spawned_items.remove_at(item_index)
		
func get_active_items_of_type(type:MineItem.ItemType) -> Array[MineItem]:
	var active_items:Array[MineItem]
	for item in spawned_items:
		if item.type == type:
			active_items.append(item)
	return active_items
	
func remap_range(value, InputA, InputB, OutputA, OutputB) -> float:
	return(value - InputA) / (InputB - InputA) * (OutputB - OutputA) + OutputA
				
