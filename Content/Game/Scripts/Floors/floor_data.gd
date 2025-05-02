extends Resource
class_name FloorData

@export var floor_level:int
@export var layers:Array[Texture2D]
@export var layer_healths:Array[int]
@export var debris_color:Color

@export_category("Obstacles Settings")
@export var possible_obstacles:Dictionary

@export_category("Treasure Spawn Settings")
@export var possible_treasures:Dictionary
@export var treasure_spawn_density:int

@export_category("Utility Spawn Settings")
@export var possible_utilities:Dictionary
@export var utility_spawn_density:int

@export var is_destroyable:bool = true

func get_total_health() -> int:
	var total_health:int=0
	
	for health in layer_healths:
		total_health+=health
	return total_health
	
func get_layer_by_health(health_remaining:int) -> Texture2D:
	var cummulative_health:int=0
	var layer_index:int=0
	
	for i in range(layers.size()):
		cummulative_health += layer_healths[i]
		layer_index = i
		if health_remaining <= cummulative_health:
			break
			
	return layers[layer_index]
