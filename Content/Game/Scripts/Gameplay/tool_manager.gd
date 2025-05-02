extends Node2D
class_name ToolManager

@export var cam:PlayerCamera
@export var input:PlayerInput

@export var speed:float = 100
@export var stiffness:float = 1000.0
@export var damping:float = 0.1

@export var damage_colors:Dictionary

@export var mining_tools:Node2D
@export var default_tool_id:int = 1

signal on_tool_hit(tool:MiningTool)
# Initial velocity of the sprite
var velocity: Vector2 = Vector2.ZERO

var quickbelt:Quickbelt
var toolbelt:Toolbelt

var active_tool:MiningTool

var map_manager:MapManager
var player_manager:PlayerManager

var focused_tile:MineTile

signal on_tool_switched(new_tool_id:int)
# Called when the node enters the scene tree for the first time.
func setup():
	for tool in mining_tools.get_children():
		tool.visible=false
	
	switch_tool(default_tool_id)
	player_manager = get_tree().get_first_node_in_group("Player")
	player_manager.on_freeze_state_changed.connect(handle_player_freeze)
	
	quickbelt = player_manager.hud.quickbelt
	quickbelt.on_tool_selected.connect(switch_tool)
	
	toolbelt = player_manager.hud.toolbelt
	toolbelt.on_tool_selected.connect(switch_tool)
	#toolbelt will connect to the toolmanager later on, so gotta initalize it manually first
	toolbelt.update_tool_selection(default_tool_id)	
	
	self.global_position = get_global_mouse_position()
		
	map_manager = get_tree().get_first_node_in_group("MapManager")

	#get_parent().call_deferred("move_child",self,get_parent().get_child_count()-1)
	pass # Replace with function body


var jiggle_start_delay:float = 0.3
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
			
	if active_tool.is_hitting:
		return
		
	if focused_tile == null:
		if mining_tools.visible:
			mining_tools.visible=false
		return
	else:
		if !mining_tools.visible:
			mining_tools.visible=true
		
	var target_position:Vector2 = focused_tile.global_position
		
	#if jiggle_start_delay>0:
		#self.global_position = target_position
		#jiggle_start_delay-=delta
		#return
		
	# Calculate the difference between the sprite's position and the mouse position
	var difference: Vector2 = target_position - self.global_position
	# Calculate the acceleration based on Hooke's law (F = -kx) and damping (F = -bv)
	var acceleration: Vector2 = difference * stiffness - velocity * damping
	
	velocity += acceleration * delta
	self.global_position += velocity * delta
	

func switch_tool(tool_id:int) -> void:
	if active_tool!=null:
		active_tool.visible=false
	active_tool = mining_tools.get_child(tool_id)
	active_tool.visible=true
	
	on_tool_switched.emit(tool_id)
	
	if focused_tile!=null:
		update_hit_indications()
	
func get_hit_data(grid_pos:Vector2) -> Dictionary:
	return active_tool.get_hit_cells(grid_pos)
	
func is_hitting() -> bool:
	return active_tool.is_hitting
	
func handle_player_freeze(frozen:bool) -> void:
	if frozen:
		hide_all_indications()
	else:
		if focused_tile!=null:
			update_hit_indications()
		
	
func update_hit_indications() -> void:
	hide_all_indications()
	#don't show any indications even around the tile if the main one not hittable	
	if !focused_tile.can_hit():
		return
		
	var hover_cells:Dictionary = get_hit_data(focused_tile.pos_in_grid)
	
	#enable only relevant tiles with specified damage color	
	for key in hover_cells.keys():
		if !map_manager.is_in_bounds(key):
			continue
			
		if !map_manager.get_topmost_active_tile_at_position(key).can_hit():
			continue
			
		var hover_indication:HoverIndication = map_manager.hover_indications[key]
		var damage:int = hover_cells[key]
		var damage_color:Color =  damage_colors[damage]
		hover_indication.show(damage_color)
		
func hide_all_indications() -> void:
	for key in map_manager.hover_indications.keys():
		var indication:HoverIndication = map_manager.hover_indications[key]
		indication.hide()
	
func process_hit(successful_hit:bool, hit_pos:Vector2) -> void:
	on_tool_hit.emit(active_tool)
	await active_tool.play_hit_anim(successful_hit,hit_pos)

func focus_tile(selected_tile:MineTile) -> void:
	if focused_tile!=null:
		on_tile_focus_lost(focused_tile)
	
	if selected_tile.can_hit():
		on_tile_focused(selected_tile)
		focused_tile = selected_tile
	
func on_tile_focused(new_focused_tile:MineTile) -> void:
	new_focused_tile.focus_start()
	focused_tile = new_focused_tile
	update_hit_indications()
	pass
	
func on_tile_focus_lost(tile:MineTile) -> void:
	tile.focus_end()
	hide_all_indications()
	focused_tile=null
	pass
