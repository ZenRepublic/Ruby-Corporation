extends Node
class_name CampaignDetails

@export var screen_manager:ScreenManager

@export var interactor:CampaignInteractor
@export var leaderboard:CampaignLeaderboard

var campaign_key:Pubkey
var campaign_data:Dictionary

func setup_campaign_details(id:String, data:Dictionary) -> void:
	screen_manager.switch_active_panel(0)
	
	campaign_key = Pubkey.new_from_string(id)
	campaign_data = data
	
	await interactor.set_campaign_data(campaign_key,campaign_data)
	interactor.campaign_player_manager.on_game_started.connect(handle_game_start)
	screen_manager.switch_active_panel(1)
	
func handle_game_start(campaign:Pubkey,data:Dictionary,player_data:Dictionary) -> void:
	var menu_manager:MenuManager = get_tree().get_first_node_in_group("MenuManager") as MenuManager
	menu_manager.load_gig(campaign,data,player_data)
	queue_free()
	
func show_leaderboard() -> void:
	screen_manager.switch_active_panel(0)
	
	await leaderboard.load_leaderboard(campaign_key,campaign_data)
	
	screen_manager.switch_active_panel(2)
	
