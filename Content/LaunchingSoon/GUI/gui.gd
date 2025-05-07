extends Control
class_name GUI

@export var admin_panel:AdminPanel
@export var placement_ui:PlacementUI
@export var start_screen:Control
@export var win_screen:Control
@export var lose_screen:Control

var launch_controller:LaunchController

func _init() -> void:
	add_to_group("GUI")
	
func _ready() -> void:
	start_screen.visible=false
	win_screen.visible=false
	lose_screen.visible=false
	admin_panel.visible=false
	
	launch_controller = get_tree().get_first_node_in_group("LaunchController") as LaunchController
	launch_controller.setup_complete.connect(setup_admin_panel)
	
func setup_admin_panel() -> void:
	admin_panel.set_token_visual(launch_controller.get_reward_token_visual())
	admin_panel.visible=true
	
func hide_admin_panel() -> void:
	admin_panel.visible=false
	
func handle_start_ui() -> void:
	var animator:AnimationPlayer = start_screen.get_child(0) as AnimationPlayer
	animator.play("Start")
	start_screen.visible=true
	
func handle_win_ui() -> void:
	var animator:AnimationPlayer = win_screen.get_child(0) as AnimationPlayer
	animator.play("GoodLuck")
	win_screen.visible=true
	
func handle_lose_ui() -> void:
	var animator:AnimationPlayer = lose_screen.get_child(0) as AnimationPlayer
	animator.play("Fired")
	lose_screen.visible=true

	
	
