extends CampaignPlayerManager
class_name TokenCampaignPlayerManager

@export var min_sol_to_enter:float = 0.002
@export var mode_screen_manager:ScreenManager
@export var balance_displayable:DisplayableAsset
@export var price_displayable:DisplayableAsset
@export var price_label:NumberLabel

@export var play_button:ButtonLock

func _ready() -> void:
	play_button.pressed.connect(start_game)
	
func setup_player_selection(campaign:Pubkey,data:Dictionary) -> void:
	super.setup_player_selection(campaign,data)
	var game_mint:Pubkey = data["token_config"]["spending_mint"]
	if mode_screen_manager!=null:
		mode_screen_manager.switch_active_panel(data["token_config"]["token_use"])
		
	curr_player_data = await get_player_data(SolanaService.wallet.get_pubkey())
	var spending_token:Token = await SolanaService.asset_manager.get_asset_from_mint(game_mint,true)
	await balance_displayable.set_data(spending_token)
	await price_displayable.set_data(spending_token)
	price_label.set_value(data["token_config"]["energy_price"]/pow(10,data["token_config"]["spending_mint_decimals"]))
	
	play_button.clear_gating()
	play_button.lock_active=true
	play_button.add_token_gate(null,min_sol_to_enter)
	play_button.add_token_gate(spending_token.mint,price_label.get_number_value())
	play_button.try_unlock()
	

func get_player_data(player_id:Pubkey) -> Dictionary:
	var campaign_player_pda:Pubkey = ClubhousePDA.get_campaign_player_pda(campaign_key,player_id)
	var player_data:Dictionary =  await SolanaService.fetch_program_account_of_type(ClubhouseProgram.get_program(),"CampaignPlayer",campaign_player_pda)
	if player_data.size()==0:
		#if there's no data, means fresh account	
		player_data = {
			"player_identity":{"identity_type":2,"pubkey":player_id},
			"in_game":false
		}

	return player_data
	
func start_game() -> void:
#	refresh data just in case
	curr_player_data = await get_player_data(SolanaService.wallet.get_pubkey())
	var reward_mint:Pubkey = campaign_data["reward_mint"]
	var house_data:Dictionary = await ClubhouseProgram.utils.get_house_data(campaign_data["house"])
	var oracle:Pubkey = house_data["config"]["oracle_key"]
	
	var game_data:Dictionary = {
		"game_mint":campaign_data["token_config"]["spending_mint"],
		"token_use":campaign_data["token_config"]["token_use"]
	}
	
	var force_end_previous_game:bool = curr_player_data["in_game"]
	
	#multi instruction doesn't work. signing 2 transactions instead temporarily	
	#if force_end_previous_game:
		#var end_game_tx_data:TransactionData = await ClubhouseProgram.claim_reward(campaign_data["house"],oracle,campaign_key,game_data,reward_mint,0)
		#if !end_game_tx_data.is_successful():
			#return
		#force_end_previous_game=false
		
	var tx_data:TransactionData = await ClubhouseProgram.start_game(campaign_data["house"],oracle,campaign_key,reward_mint,game_data,force_end_previous_game)
	if tx_data.is_successful():
		on_game_started.emit(campaign_key,campaign_data,curr_player_data)
