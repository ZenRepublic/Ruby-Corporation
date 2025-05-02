extends Node
class_name CampaignPlayerManager

var campaign_data:Dictionary
var campaign_key:Pubkey

var curr_player_data:Dictionary
var curr_player_pda:Pubkey

signal on_game_started(campaign_key:Pubkey,campaign_data:Dictionary,player_data:Dictionary)

func setup_player_selection(campaign:Pubkey,data:Dictionary) -> void:
	campaign_key = campaign
	campaign_data = data
	pass
	
	
