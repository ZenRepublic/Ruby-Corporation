extends Node
class_name ScreenManager

@export var starting_panel:Control
@export var screens:Array[Control]
var curr_active_panel:Control
var prev_panel:Control

signal on_panel_changed(new_active_panel:int)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for screen in screens:
		if screen == starting_panel:
			screen.visible=true
		else:
			screen.visible=false
			
	curr_active_panel = starting_panel
	
func switch_to_main_panel() -> void:
	if starting_panel == null:
		return
		
	if curr_active_panel == starting_panel:
		return
	
	for i in range(screens.size()):
		if screens[i] == starting_panel:
			switch_active_panel(i)
			break
	

func switch_active_panel(new_panel_id:int) -> void:
	if screens[new_panel_id] == curr_active_panel:
		return
		
	if curr_active_panel!=null:
		curr_active_panel.visible = false
		prev_panel = curr_active_panel

	curr_active_panel = screens[new_panel_id]
	curr_active_panel.visible =true
	on_panel_changed.emit(new_panel_id)
	
	
func back_to_previous_panel() -> void:
	if curr_active_panel!=null:
		curr_active_panel.visible=false
	
	prev_panel.visible=true
	
	var temp_panel = curr_active_panel
	curr_active_panel = prev_panel
	prev_panel = temp_panel
	

func close_active_panel()->void:
	if curr_active_panel!=null:
		curr_active_panel.visible=false
		curr_active_panel=null
		
func get_panel_by_id(panel_id:int) -> Control:
	return screens[panel_id]
