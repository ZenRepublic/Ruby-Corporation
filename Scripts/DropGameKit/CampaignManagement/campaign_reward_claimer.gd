extends Node
class_name CampaignRewardClaimer

@export var rewards_display_scn:PackedScene

var house_data:Dictionary
var campaign_data:Dictionary
var player_data:Dictionary

var campaign_key:Pubkey

var reward_mint_decimals:int=0
var max_reward_lamports:int=0

var campaign_token:Token

var max_game_score:float

signal on_reward_claimed

func setup_claimer(campaign_key:Pubkey, campaign_data:Dictionary, player_data:Dictionary, max_score:float) -> void:
	max_game_score = max_score
	
	house_data = await ClubhouseProgram.utils.get_active_house_data()
	if house_data.size()==0:
		print("No active house found. Skipping setting rewards")
		return
		
	self.campaign_key = campaign_key
	self.campaign_data = campaign_data
	self.player_data = player_data
		
	reward_mint_decimals = campaign_data["reward_mint_decimals"]
	campaign_token = await SolanaService.asset_manager.get_asset_from_mint(campaign_data["reward_mint"],true)
	
	max_reward_lamports = campaign_data["max_rewards_per_game"]

	
func get_token_unit_price(in_lamports:bool=true) -> float:
	var score_point_value_in_reward_lamports:int = floori(max_reward_lamports/max_game_score)
	
	if in_lamports:
		return score_point_value_in_reward_lamports
	else:
		var value_in_number:float = float(score_point_value_in_reward_lamports)/pow(10,reward_mint_decimals)
		return round(value_in_number*pow(10,reward_mint_decimals)) / pow(10,reward_mint_decimals)
	
func get_token_value(score:float, in_lamports:bool=true) -> float:
	var token_value_in_lamports:int = clamp(get_token_unit_price(true) * score,0,max_reward_lamports)
	
	if in_lamports:
		return token_value_in_lamports
	else:
		return float(token_value_in_lamports)/pow(10,reward_mint_decimals)
		
func get_reward_token_texture() -> Texture2D:
	if campaign_token == null:
		return null
	return campaign_token.image
	
	
func get_max_reward() -> float:
	return float(max_reward_lamports)/pow(10,reward_mint_decimals)
		

func claim_reward(claim_amount:float) -> void:
	var reward_amount_lamports:int = clampi(claim_amount*pow(10,reward_mint_decimals),0,max_reward_lamports)
	var house_pda:Pubkey = campaign_data["house"]
	var reward_mint:Pubkey = campaign_data["reward_mint"]
	var oracle:Pubkey = house_data["config"]["oracle_key"]
	
	var game_data:Dictionary = {}
	if player_data["player_identity"]["identity_type"] == 1 or player_data["player_identity"]["identity_type"] == 3:
		game_data = {
			"asset":player_data["player_identity"]["pubkey"],
			"asset_type":player_data["player_identity"]["identity_type"]
			}
	
	var tx_data:TransactionData = await ClubhouseProgram.claim_reward(house_pda,oracle,campaign_key,game_data,reward_mint,reward_amount_lamports)
	on_reward_claimed.emit(tx_data.is_successful())
	
var rewards_display_instance:CampaignRewardDisplay
func pop_rewards_display() -> void:
	rewards_display_instance = rewards_display_scn.instantiate()
	rewards_display_instance.on_replay_pressed.connect(handle_replay)
	rewards_display_instance.on_return_pressed.connect(handle_return)
	get_tree().root.add_child(rewards_display_instance)
	
	await rewards_display_instance.setup_rewards_display()
	
func handle_replay(campaign_key:Pubkey,campaign_data:Dictionary,player_data:Dictionary) -> void:
	rewards_display_instance.on_replay_pressed.disconnect(handle_replay)
	rewards_display_instance.on_return_pressed.disconnect(handle_return)
	
	SceneManager.reload_scene(true,-1,{
		"FreePlay":false,
		"CampaignKey":campaign_key,
		"CampaignData":campaign_data,
		"PlayerData":player_data
	})
	
	await get_tree().create_timer(0.5).timeout
	rewards_display_instance.queue_free()
	
func handle_return() -> void:
	rewards_display_instance.on_replay_pressed.disconnect(handle_replay)
	rewards_display_instance.on_return_pressed.disconnect(handle_return)
	
	SceneManager.load_previous_scene(true,-1,0.0)
	
	await get_tree().create_timer(0.5).timeout
	rewards_display_instance.queue_free()
	
