extends Node
class_name CampaignManager

@export var campaign_name_label:Label
@export var gate_displayable:DisplayableAsset
@export var owner_displayable:DisplayableAsset
@export var campaign_type_label:Label
@export var max_reward_displayable:DisplayableAsset

@export var treasury_token_displayable:DisplayableAsset

@export var total_games_label:Label
@export var unique_players_label:Label
@export var deposit_token_displayable:DisplayableAsset
@export var not_available_deposit_label:Label

@export var leaderboard:CampaignLeaderboard

@export var fees_collected:NumberLabel

@export var close_button:TimedButton

var campaign_key:Pubkey
var curr_campaign_data:Dictionary

signal on_campaign_closed

# Called when the node enters the scene tree for the first time.
func set_campaign(campaign_id:String,campaign_data:Dictionary) -> void:
	curr_campaign_data = campaign_data
	print(campaign_id)
	print(curr_campaign_data)
	var result = await ClubhouseProgram.utils.get_managers_in_use(curr_campaign_data["house"])
	#print(result["2RMG75ydGKLcviZZvU4tL7kZ4iGSVQELhnfXHxPCjWvx"]["manager"].to_string())
	#print(result["2RMG75ydGKLcviZZvU4tL7kZ4iGSVQELhnfXHxPCjWvx"]["campaign"].to_string())
	#print(result["2RMG75ydGKLcviZZvU4tL7kZ4iGSVQELhnfXHxPCjWvx"]["house"].to_string())
	
	campaign_key = Pubkey.new_from_string(campaign_id)
	campaign_name_label.text = campaign_data["campaign_name"]
	total_games_label.text = str(campaign_data["total_games"])
	unique_players_label.text = str(campaign_data["player_count"])
	
	var total_fees_collected:float = campaign_data["unclaimed_sol_fees"]/pow(10,9)
#	divide by 100 to get percentage from basis points. if rewards tax is 150, that means 15% that means 0.15
	var creator_cut:float = total_fees_collected * (campaign_data["house_config_snapshot"]["rewards_tax"]/1000)
	var final_fees_collected:float = total_fees_collected - creator_cut
	fees_collected.set_value(final_fees_collected/pow(10,9))
	
	var gate_asset:WalletAsset
	if campaign_data["nft_config"] != null:
		gate_asset = await SolanaService.asset_manager.get_asset_from_mint(campaign_data["nft_config"]["collection"],true)
		campaign_type_label.text = "NFT"
	elif campaign_data["token_config"] != null:
		gate_asset = await SolanaService.asset_manager.get_asset_from_mint(campaign_data["token_config"]["spending_mint"],true)
		campaign_type_label.text = "Token"
		
	if gate_asset!=null:
		gate_displayable.set_data(gate_asset)
	else:
		push_error("Campaign Gate asset Failed to load...")
	
	if campaign_data["manager_identity"]["identity_type"] != 0:
		var manager_mint:Pubkey = campaign_data["manager_identity"]["pubkey"]
		var campaign_owner:WalletAsset = await SolanaService.asset_manager.get_asset_from_mint(manager_mint)
		if campaign_owner!=null:
			owner_displayable.set_data(campaign_owner)
			
	var campaign_token:Token = await SolanaService.asset_manager.get_asset_from_mint(campaign_data["reward_mint"],true)
	campaign_token.token_account = ClubhousePDA.get_campaign_vault_pda(campaign_key)
	campaign_token.balance = campaign_data["rewards_available"] / pow(10,campaign_data["reward_mint_decimals"])
	campaign_token.decimals = campaign_data["reward_mint_decimals"]
	await treasury_token_displayable.set_data(campaign_token)
	
	await max_reward_displayable.set_data(campaign_token)
	max_reward_displayable.balance_label.set_value(campaign_data["max_rewards_per_game"]/pow(10,campaign_data["reward_mint_decimals"]))
	
	#show deposit amount if token campaign and not burn mode	
	if campaign_data["token_config"] != null and campaign_data["token_config"]["token_use"] != 1:
		not_available_deposit_label.visible=false
		deposit_token_displayable.visible=true
		
		var game_token:Token = await SolanaService.asset_manager.get_asset_from_mint(campaign_data["token_config"]["spending_mint"],true)
		game_token.token_account = ClubhousePDA.get_deposit_vault_pda(campaign_key)
		game_token.decimals = campaign_data["token_config"]["spending_mint_decimals"]
		await deposit_token_displayable.set_data(game_token)
	else:
		deposit_token_displayable.visible=false
		not_available_deposit_label.visible=true
	
#	allow only program admins to end campaign before it expires
	var is_admin:bool = await ClubhouseProgram.utils.is_admin(SolanaService.wallet.get_pubkey())
	if is_admin:
		close_button.disabled=false
		
	close_button.start_timer(campaign_data["time_span"]["start_time"],campaign_data["time_span"]["end_time"])
	
	leaderboard.load_leaderboard(campaign_key,curr_campaign_data,false,5)
	
func close() -> void:
	var house_pda:Pubkey = curr_campaign_data["house"]
	var campaign_data:Dictionary =  await SolanaService.fetch_program_account_of_type(ClubhouseProgram.get_program(),"Campaign",campaign_key)
	
	var manager_data= null
	if campaign_data["manager_identity"]["identity_type"] != 0:
		manager_data={
			"asset":campaign_data["manager_identity"]["pubkey"],
			"asset_type": campaign_data["manager_identity"]["identity_type"]
		}
		
	var tx_data:TransactionData = await ClubhouseProgram.close_campaign(house_pda,campaign_key,curr_campaign_data,manager_data)
	
	if tx_data.is_successful():
		on_campaign_closed.emit()
