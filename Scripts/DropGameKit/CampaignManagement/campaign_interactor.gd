extends Node
class_name CampaignInteractor

@export var campaign_name_label:Label
@export var gate_displayable:DisplayableAsset
@export var manager_displayable:DisplayableAsset
@export var reward_token_displayable:DisplayableAsset
@export var max_reward_label:NumberLabel
@export var campaign_timer:TimedButton
@export var campaign_expired_panel:Control
@export var not_logged_in_panel:Control
@export var leaderboard_scn:PackedScene

@export_category("NFT Campaign Settings")
@export var nft_player_manager:NFTCampaignPlayerManager

@export_category("Token Campaign Settings")
@export var token_player_manager:TokenCampaignPlayerManager

var curr_campaign_data:Dictionary
var campaign_key:Pubkey

var campaign_player_manager:CampaignPlayerManager

signal on_game_started(campaign_key:Pubkey,campaign_data:Dictionary,player_data:Dictionary)

func _ready() -> void:
	campaign_timer.on_timer_finished.connect(disable_campaign)
	
	nft_player_manager.visible=false
	token_player_manager.visible=false
	
func game_start_relay(campaign:Pubkey,data:Dictionary,player_data:Dictionary) -> void:
	on_game_started.emit(campaign,data,player_data)
		
# Called when the node enters the scene tree for the first time.
func set_campaign_data(id:String,data:Dictionary) -> void:
	print(data)
	disable_campaign(false)
	curr_campaign_data = data
	campaign_key = Pubkey.new_from_string(id)
	campaign_name_label.text = data["campaign_name"]
	
	if data["nft_config"] != null:
		await setup_nft_campaign()
	elif data["token_config"] != null:
		await setup_token_campaign()
		
	if SolanaService.wallet.is_logged_in():
		await campaign_player_manager.setup_player_selection(campaign_key,curr_campaign_data)
	else:
		not_logged_in_panel.visible=true
		campaign_player_manager.visible=false
		SolanaService.wallet.on_login_success.connect(setup_player_selection)
		
	
	if data["manager_mint"] != null:
		var manager_asset:WalletAsset = await SolanaService.asset_manager.get_asset_from_mint(data["manager_mint"])
		if manager_asset!=null:
			manager_displayable.set_data(manager_asset)
			
		
	var campaign_token:Token = await SolanaService.asset_manager.get_asset_from_mint(data["reward_mint"],true)
	campaign_token.token_account = ClubhousePDA.get_campaign_vault_pda(campaign_key)
	campaign_token.decimals = data["reward_mint_decimals"]
	await reward_token_displayable.set_data(campaign_token)
	
	max_reward_label.set_value(data["max_rewards_per_game"]/pow(10,data["reward_mint_decimals"]))
	
	var reserved_amount:float = max_reward_label.get_number_value() * data["active_games"]
	if reward_token_displayable.asset.get_balance() < (max_reward_label.get_number_value()+reserved_amount):
		reward_token_displayable.balance_label.set_value(0)
		disable_campaign()
		
	campaign_timer.start_timer(data["time_span"]["start_time"],data["time_span"]["end_time"])
	if campaign_timer.is_finished():
		disable_campaign()
	
func disable_campaign(disable:bool=true) -> void:
	if campaign_expired_panel!=null:
		campaign_expired_panel.visible=disable
		
	if campaign_player_manager!=null:
		campaign_player_manager.visible = !disable
	pass
	
func setup_nft_campaign() -> void:
	if campaign_player_manager!=null:
		campaign_player_manager.on_game_started.disconnect(game_start_relay)
		campaign_player_manager.visible=false

	nft_player_manager.on_game_started.connect(game_start_relay)
	nft_player_manager.visible=true
	
	var mine_gate_asset:WalletAsset = await SolanaService.asset_manager.get_asset_from_mint(curr_campaign_data["nft_config"]["collection"],true)
	await gate_displayable.set_data(mine_gate_asset)
	
	campaign_player_manager = nft_player_manager
	pass
	
	
func setup_token_campaign() -> void:
	if campaign_player_manager!=null:
		campaign_player_manager.on_game_started.disconnect(game_start_relay)
		campaign_player_manager.visible=false
		
	token_player_manager.on_game_started.connect(game_start_relay)
	token_player_manager.visible=true
	
	var mine_gate_asset:WalletAsset = await SolanaService.asset_manager.get_asset_from_mint(curr_campaign_data["token_config"]["spending_mint"],true)
	await gate_displayable.set_data(mine_gate_asset)
	
	campaign_player_manager = token_player_manager
	pass
	
func setup_player_selection() -> void:
	not_logged_in_panel.visible=false
	await campaign_player_manager.setup_player_selection(campaign_key,curr_campaign_data)
	campaign_player_manager.visible=true
		
func load_leaderboard() -> void:
	var leaderboard:CampaignLeaderboard = leaderboard_scn.instantiate()
	get_tree().root.add_child(leaderboard)
	leaderboard.load_leaderboard(campaign_key,curr_campaign_data,false,10)
		
