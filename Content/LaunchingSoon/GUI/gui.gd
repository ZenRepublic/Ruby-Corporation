extends Control
class_name GUI

@export var admin_panel:AdminPanel
@export var campaign_reward_display:CampaignRewardDisplay
@export var win_screen:GameEndUI
@export var lose_screen:GameEndUI

@export var effect_scenes:Dictionary
@export var placement_effect_scenes:Array[PackedScene]

var launch_controller:LaunchController

func _init() -> void:
	add_to_group("GUI")
	
func _ready() -> void:
	campaign_reward_display.visible=false
	win_screen.visible=false
	lose_screen.visible=false
	admin_panel.visible=false
	
	launch_controller = get_tree().get_first_node_in_group("LaunchController") as LaunchController
	launch_controller.setup_complete.connect(setup_admin_panel)
	
func setup_admin_panel() -> void:
	admin_panel.set_token_visual()
	admin_panel.visible=true
	
func hide_admin_panel() -> void:
	admin_panel.visible=false
	
func handle_win_ui(earn_amount:float) -> void:
	win_screen.visible=true
	win_screen.on_reward_claimed.connect(show_rewards_display, CONNECT_ONE_SHOT)
	
	win_screen.setup_ui(earn_amount,launch_controller.free_play_mode)
	
func handle_lose_ui(severance_amount:float) -> void:
	lose_screen.visible=true
	lose_screen.on_reward_claimed.connect(show_rewards_display, CONNECT_ONE_SHOT)
	
	lose_screen.setup_ui(severance_amount,launch_controller.free_play_mode)
	
func show_rewards_display() -> void:
	win_screen.visible=false
	lose_screen.visible=false
	
	campaign_reward_display.visible=true
	await campaign_reward_display.setup_rewards_display()
	
	
func do_effect(name:String) -> void:
	var effect_instance:Control = effect_scenes[name].instantiate()
	add_child(effect_instance)
	
func do_placement_effect(place_tier:LaunchSettings.PLACE_TIER) -> void:
	var effect_instance:Control = placement_effect_scenes[place_tier-1].instantiate()
	add_child(effect_instance)
	await get_tree().create_timer(1.0).timeout
	effect_instance.queue_free()

	
	
