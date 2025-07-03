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
	
	screen_manager.switch_active_panel(1)
	
func show_leaderboard() -> void:
	screen_manager.switch_active_panel(0)
	
	await leaderboard.load_leaderboard(campaign_key,campaign_data)
	
	screen_manager.switch_active_panel(2)
	
