extends Control
class_name Quickbelt

@onready var tool_menu:RadialMenuAdvanced = $ToolMenu
@onready var animation_player:AnimationPlayer = $AnimationPlayer

var player_manager:PlayerManager

signal on_tool_selected
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_manager = get_tree().get_first_node_in_group("Player")
	player_manager.input_handler.on_right_click.connect(handle_toolbelt)
	
	tool_menu.slot_selected.connect(handle_tool_click)
	
	self.visible=false


func handle_toolbelt(clicked:bool) -> void:
	#if clicked with slot selected signal, then dont double process when released right click	
	if !clicked and !self.visible:
		return
		
#	don't allow to open toolbelt if mouse already showing, means its UI mode
	if clicked and player_manager.input_handler.mouse_active:
		return
		
	self.visible = clicked
	
	#set menu to be right in the middle of mouse	
	tool_menu.global_position = get_global_mouse_position()
	
	if clicked:
		animation_player.play("ToolbeltAppear")
	#when right click is released, update the tool selection, unless it's -2
	if !clicked and tool_menu.selection >= 0:
		update_tool_selection(tool_menu.selection)
		
func update_tool_selection(tool_index:int) -> void:
#	for some reason indexes work in counterclockwise direction, we need to flip it
	var clockwise_index:int = (tool_menu.get_child_count() - tool_index) % tool_menu.get_child_count()
	on_tool_selected.emit(clockwise_index)
	
func handle_tool_click(_selected_child,_tool_index:int) -> void:
	#the toolbelt might get a bit bugged, good to have a fallback click with left
	#button to also select the tool, hiding the belt in process
	handle_toolbelt(false)	
