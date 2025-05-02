extends Node
class_name CampaignRewardClaimer

@export var score_to_max_reward:float = 300
var house_data
var campaign_data
var player_data
var campaign_key:Pubkey

var reward_mint_decimals:int
var max_reward_lamports:int

var campaign_token:Token

signal on_reward_claimed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	house_data = await ClubhouseProgram.utils.get_active_house_data()
	if house_data.size()==0:
		print("No active house found. Skipping setting rewards")
		return
		
	campaign_key = SceneManager.get_interscene_data("CampaignKey")
	campaign_data = SceneManager.get_interscene_data("CampaignData")
	player_data = SceneManager.get_interscene_data("PlayerData")
	
	if campaign_data == null or player_data == null:
		return
		
	reward_mint_decimals = campaign_data["reward_mint_decimals"]
	campaign_token = await SolanaService.asset_manager.get_asset_from_mint(campaign_data["reward_mint"],true)
	
	max_reward_lamports = campaign_data["max_rewards_per_game"]

	
func get_token_unit_price(in_lamports:bool=true) -> float:
	var score_point_value_in_reward_lamports:int = floori(max_reward_lamports/score_to_max_reward)
	
	if in_lamports:
		return score_point_value_in_reward_lamports
	else:
		var value_in_number:float = float(score_point_value_in_reward_lamports)/pow(10,reward_mint_decimals)
		return round(value_in_number*pow(10,reward_mint_decimals)) / pow(10,reward_mint_decimals)
	
func get_token_value(score:int, in_lamports:bool=true) -> float:
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
	
