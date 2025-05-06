extends Control
class_name GUI

@export var admin_panel:AdminPanel
@export var placement_ui:PlacementUI
@export var win_screen:Control
@export var lose_screen:Control

var launch_controller:LaunchController

func _init() -> void:
	add_to_group("GUI")
	
func _ready() -> void:
	win_screen.visible=false
	lose_screen.visible=false
	admin_panel.visible=false
	
	launch_controller = get_tree().get_first_node_in_group("LaunchController") as LaunchController
	launch_controller.setup_complete.connect(setup_gui)
	
func setup_gui() -> void:
	admin_panel.set_token_visual(launch_controller.get_reward_token_visual())
	admin_panel.visible=true
	
func handle_win_ui() -> void:
	win_screen.visible=true
	
func handle_lose_ui() -> void:
	lose_screen.visible=true

	
	
