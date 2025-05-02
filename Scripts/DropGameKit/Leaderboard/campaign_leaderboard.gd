extends Node
class_name CampaignLeaderboard

@export var leaderboard_display_system:AccountDisplaySystem
@export var allow_copy_player_address:bool

var current_campaign_data:Dictionary
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	leaderboard_display_system.on_account_added.connect(set_extra_data)
	pass # Replace with function body.


func load_leaderboard(campaign_key:Pubkey,campaign_data:Dictionary,force_refresh:bool=false,amount_to_load:int=10) -> void:
	if campaign_data == current_campaign_data && !force_refresh:
		return
		
	current_campaign_data = campaign_data
	
   #offset 8 by default (bump), and 33 for player identity (1 for identity type and 32 for identity pubkey)	
	var filter:Array = [
		{"memcmp" : { "offset":41, "bytes": campaign_key.to_string()}}
	]	
	leaderboard_display_system.set_sort_data("rewards_claimed",true,amount_to_load)
	leaderboard_display_system.set_list(ClubhouseProgram.get_program(),"CampaignPlayer",filter,amount_to_load,false)
	leaderboard_display_system.refresh_account_list()
	
func set_extra_data(entry:AccountDisplayEntry) -> void:
	if entry == null:
#		shitty solution, but can be that entry has been deleted before signal came
		return
	var campaign_token:Token = await SolanaService.asset_manager.get_asset_from_mint(current_campaign_data["reward_mint"],true)
	entry.token_visual.texture = campaign_token.image
	
	var lamport_player_value = entry.player_score.get_number_value()
	entry.player_score.set_value(lamport_player_value/pow(10,current_campaign_data["reward_mint_decimals"]))
	
	entry.show_copy_button(allow_copy_player_address)
	
func close() -> void:
	queue_free()
