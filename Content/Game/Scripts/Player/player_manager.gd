extends Node2D
class_name PlayerManager

@onready var cam:PlayerCamera = $Cam
@onready var stats:PlayerStats = $Stats
@onready var hud:PlayerHud = $HUD
@onready var inventory:PlayerInventory = $Inventory

@export var input_handler:PlayerInput
@export var tool_manager:ToolManager
@export var move_speed:float = 2.0
@export var focus_speed:float = 5.0
@export var move_select_sensitivity:float = 30.0

var map_manager:MapManager
var game_manager:GameManager
var frozen:bool

var time_delta:float

signal on_freeze_state_changed(frozen:bool)

func _init():
	add_to_group("Player")
	
# Called when the node enters the scene tree for the first time.
func _ready():
	input_handler.on_drag.connect(move)
	input_handler.on_zoom.connect(zoom)
	input_handler.on_click.connect(start_move)
	input_handler.on_click_release.connect(try_select)
	
	map_manager = get_tree().get_first_node_in_group("MapManager")
	game_manager = get_tree().get_first_node_in_group("GameManager")

	self.global_position = map_manager.get_center_position()
	tool_manager.setup()
	inventory.clear_items()
	
	if map_manager.is_generated:
		move_to_center()
	else:
		map_manager.on_map_generated.connect(move_to_center)		
		
func _process(delta: float) -> void:
	time_delta = delta
	
func move_to_center(smooth_move:bool=false) -> void:
	await move_to(map_manager.get_center_position(),0,smooth_move)
	
func move_to(pos:Vector2,zoom_strength:float=0,smooth_move:bool=true) -> void:
	if self.global_position == pos:
		return
		
	if !smooth_move:
		self.global_position = pos
		cam.set_zoom_strength(zoom_strength)
	else:
		var start_pos:Vector2 = self.global_position
		var target_zoom:float = lerp(cam.min_zoom,cam.max_zoom,zoom_strength)
		
		var total_distance = start_pos.distance_to(pos)
		var time_to_move:float = lerp(0.1,0.4,total_distance/focus_speed)
		var tween = create_tween()
		tween.tween_property(self, "position",pos, time_to_move).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(cam, "zoom",Vector2(target_zoom,target_zoom), time_to_move).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		
		await tween.finished
		#while move_progress<1.0:
			#self.global_position = self.global_position.move_toward(position,focus_speed)
			#var traveled_distance = start_pos.distance_to(self.global_position)
			#move_progress = clamp(traveled_distance / total_distance, 0.0, 1.0)
			#
			#cam.set_zoom_strength(lerp(start_zoom,zoom_strength,move_progress))
			#await get_tree().process_frame
			
	
func move(move_delta:Vector2)-> void:
#	with higher zoom, slower movement speed
	self.global_position += move_delta * move_speed * (1-clamp(cam.get_zoom_strength(),0,0.4))
	
	var map_bounds:Rect2 = map_manager.get_map_boundaries()
	var cam_adjusted_bounds:Rect2 = cam.get_adjusted_bounds(map_bounds)
	self.global_position = Vector2(
		clamp(self.global_position.x, cam_adjusted_bounds.position.x, cam_adjusted_bounds.position.x + cam_adjusted_bounds.size.x),
		clamp(self.global_position.y, cam_adjusted_bounds.position.y, cam_adjusted_bounds.position.y + cam_adjusted_bounds.size.y)
	)
	
func zoom(_zoom_point:Vector2, zoom_factor:float) -> void:
	cam.zoom_camera(zoom_factor)
	
	
var move_start_pos:Vector2
func start_move(_click_pos:Vector2) -> void:
	move_start_pos = self.global_position
	
func raycast_check(pos:Vector2):
	var space = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_bodies=false
	params.collide_with_areas=true
	
	var result:Array = space.intersect_point(params)
	if result.size() > 0:
		return result
	else:
		return null
	
	
func try_select(select_pos:Vector2) -> void:
	var raycast_result = raycast_check(select_pos)
	if raycast_result == null:
		return
	
	var clicked_tile:MineTile = raycast_result[0]["collider"] as MineTile
		#if whatever we collided with is not a tile		
	if clicked_tile == null or clicked_tile is not MineTile:
		return
	if !clicked_tile.can_hit():
		return
		
#		select tile if havent been moving with this click
	var distance_moved = self.global_position.distance_to(move_start_pos)
	if distance_moved<move_select_sensitivity:
		handle_tile_interaction(clicked_tile)
	
var original_zoom:float	
var original_pos:Vector2
func handle_tile_interaction(clicked_tile:MineTile) -> void:
	if frozen or tool_manager.is_hitting():
		return
		
	original_zoom = cam.get_zoom_strength()
	original_pos = self.global_position
#	first click is for focusing
	if tool_manager.focused_tile == null or (tool_manager.focused_tile.pos_in_grid != clicked_tile.pos_in_grid):
		tool_manager.focus_tile(clicked_tile)	
		#pretty cool focusing on tile based on its depth. but not intuitive			
		#var tile_depth:int = clicked_tile.tile_floor.get_depth()
		#var zoom_strength:float = 0.13*tile_depth
		#await move_to(clicked_tile.global_position,zoom_strength,true)
		return
		
	var hit_data = tool_manager.get_hit_data(clicked_tile.pos_in_grid)
	var hit_success:bool =  hit_data.keys().size() > 0
	
#	the hit may also not be a success if hit an obstacle behind the tile
	var direct_tile_damage:int = hit_data[clicked_tile.pos_in_grid]
	if clicked_tile.occupied_by != null and clicked_tile.occupied_by.type == MineItem.ItemType.OBSTACLE:
		if clicked_tile.is_lethal_hit(direct_tile_damage):
			clicked_tile.get_hit(direct_tile_damage,false)
			hit_success=false
	
	freeze(true)
	await tool_manager.process_hit(hit_success,clicked_tile.global_position)
	
	# 0 hit keys means hit not successful
	if !hit_success:
		stats.use_energy(tool_manager.active_tool.energy_cost)
		handle_tile_interaction_finish()
		return
		
	cam.start_shake(0.3,tool_manager.active_tool.shake_strength)
		
	for cell in hit_data.keys():
		var tile:MineTile = map_manager.get_topmost_active_tile_at_position(cell)
		if tile == null:
			continue
		tile.get_hit(hit_data[cell])
	
	await get_tree().create_timer(0.3).timeout
	
	#dont need to unfreeze if items discovered, cause that will happen once items are uncovered	
	if game_manager.items_uncovered.size()==0:
		handle_tile_interaction_finish()
	else:
		game_manager.on_items_uncovered.connect(handle_item_uncover_finish,CONNECT_ONE_SHOT)
		
	stats.use_energy(tool_manager.active_tool.energy_cost)

func handle_item_uncover_finish(_streak:int) -> void:
	await move_to(original_pos,original_zoom,true)
	handle_tile_interaction_finish()
	
func handle_tile_interaction_finish() -> void:	
	if tool_manager.focused_tile.destroyed:
		var next_tile:MineTile = tool_manager.focused_tile.get_tile_below()
		tool_manager.focus_tile(next_tile)
		
	freeze(false)
	
func get_closest_tile() -> MineTile:
	var raycast_result = raycast_check(self.global_position)
	if raycast_result == null:
		return null
	
	var closest_tile:MineTile = raycast_result[0]["collider"] as MineTile
		#if whatever we collided with is not a tile		
	if closest_tile == null or closest_tile is not MineTile:
		return null
	return closest_tile
		
func get_surrounding_tiles() -> Array[MineTile]:
	var closest_tile:MineTile = get_closest_tile()
	if closest_tile == null:
		return []
		
	var surrounding_tiles:Array[MineTile] = map_manager.get_surrounding_area(closest_tile.pos_in_grid,cam.light_radius)
	return surrounding_tiles
	
func freeze(state:bool) -> void:
	frozen = state
	input_handler.set_input_active(!state)
	on_freeze_state_changed.emit(state)
