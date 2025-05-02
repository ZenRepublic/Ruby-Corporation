extends Node2D
class_name BorderGenerator

@export var tile_size:int = 128
@export var desired_scale:float = 0.95
@export var corner_tiles:Array[Texture2D]
@export var side_tiles:Array[Texture2D]

func generate_borders(map_width:int,map_height:int) -> void:
	place_tile(select_random_image(corner_tiles), Vector2(-1,-1),0)
	place_tile(select_random_image(corner_tiles), Vector2(map_width,-1),90)
	place_tile(select_random_image(corner_tiles), Vector2(-1,map_height),270)
	place_tile(select_random_image(corner_tiles), Vector2(map_width,map_height),180)
	
	# Place top and bottom side tiles
	for x in range(0, map_width):
		place_tile(select_random_image(side_tiles), Vector2(x,-1),0) # Top side
		place_tile(select_random_image(side_tiles), Vector2(x, map_height), 180) # Bottom side
		
	# Place left and right side tiles
	for y in range(0, map_height):
		place_tile(select_random_image(side_tiles), Vector2(-1,y),270) # Left side
		place_tile(select_random_image(side_tiles), Vector2(map_width, y), 90) # Right side
	
	center_and_scale(map_width,map_height)
	
func select_random_image(image_array:Array) -> Texture2D:
	return image_array[randi_range(0,image_array.size()-1)]
	
func place_tile(visual:Texture2D, pos:Vector2, rot:int) -> Sprite2D:
	var tile = Sprite2D.new()
	tile.texture = visual
	add_child(tile)
	
	tile.global_position = pos * Vector2(tile_size,tile_size)
	tile.rotation_degrees += rot
	return null
	
func center_and_scale(map_width:int,map_height:int) -> void:
	var center_position = Vector2((map_width - 1) * tile_size / 2.0, (map_height - 1) * tile_size / 2.0)
	global_position = center_position
	for child in get_children():
		child.global_position -= center_position
	
	scale = Vector2.ONE*desired_scale
