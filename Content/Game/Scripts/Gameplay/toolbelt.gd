extends Control
class_name Toolbelt

@export var tool_buttons:Array[BaseButton]

@export var normal_tool_color:Color
@export var selected_tool_color:Color

var player_manager:PlayerManager
var curr_active_tool:int=-1

signal on_tool_selected
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_manager = get_tree().get_first_node_in_group("Player")
	player_manager.tool_manager.on_tool_switched.connect(update_tool_selection)
	
	for i in range(tool_buttons.size()):
		tool_buttons[i].pressed.connect(handle_tool_click.bind(i))
		tool_buttons[i].mouse_entered.connect(on_mouse_entered)

func update_tool_selection(new_tool_id:int) -> void:
	if curr_active_tool!= -1:
		tool_buttons[curr_active_tool].disabled = false
		tool_buttons[curr_active_tool].get_child(0).self_modulate = normal_tool_color
		
	tool_buttons[new_tool_id].disabled = true
	tool_buttons[new_tool_id].get_child(0).self_modulate = selected_tool_color
	
	curr_active_tool = new_tool_id
	
func handle_tool_click(button_id:int) -> void:
	update_tool_selection(button_id)
	on_tool_selected.emit(button_id)
	

func on_mouse_entered() -> void:
	pass

func on_mouse_exited() -> void:
	pass
