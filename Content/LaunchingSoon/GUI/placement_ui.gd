extends Node
class_name PlacementUI

@export var show_time:float = 1.0
@export var tier_ui_panels:Array[Control]
@export var fail_panel:Control

var curr_active_panel:Control=null

func _ready() -> void:
	for panel in tier_ui_panels:
		panel.visible=false
	fail_panel.visible=false

func show_placement_effect(place_tier:LaunchSettings.PLACE_TIER) -> void:
	if curr_active_panel!=null:
		curr_active_panel.visible=false
		
	var tier_panel:Control = tier_ui_panels[place_tier-1]
	tier_panel.visible=true
	curr_active_panel = tier_panel
	
	await get_tree().create_timer(show_time).timeout
	
	tier_panel.visible=false
	curr_active_panel = null
	
func show_fail_effect() -> void:
	fail_panel.visible=true
	await get_tree().create_timer(show_time).timeout
	fail_panel.visible=false
	
	
	
	
