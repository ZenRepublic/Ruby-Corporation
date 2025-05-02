extends AccountDisplayEntry
class_name CampaignAccount

@export var token_displayable:DisplayableAsset
@export var mine_gate_displayable:DisplayableAsset
@export var campaign_name_label:Label
@export var mine_type_label:Label

@export var mine_timer_button:TimedButton

func _ready() -> void:
	mine_timer_button.on_timer_finished.connect(deactivate_mine)
	mine_timer_button.pressed.connect(select_mine)

func setup_account_entry(id:String,account_data:Dictionary,index:int) -> void:
	super.setup_account_entry(id,account_data,index)
	campaign_name_label.text = account_data["campaign_name"]
	mine_timer_button.disabled=true
	
	var house_data:Dictionary = await ClubhouseProgram.utils.get_active_house_data()
	if house_data.size()==0:
		print("No active house found. Skipping setting account entry")
		return
		
	var campaign_key:Pubkey = Pubkey.new_from_string(id)
	
	var campaign_token:Token = await SolanaService.asset_manager.get_asset_from_mint(data["reward_mint"],true)
	campaign_token.token_account = ClubhousePDA.get_campaign_vault_pda(campaign_key)
	campaign_token.decimals = data["reward_mint_decimals"]
	await token_displayable.set_data(campaign_token)
	
	var mine_gate_asset:WalletAsset
	if data["nft_config"] != null:
		mine_gate_asset = await SolanaService.asset_manager.get_asset_from_mint(data["nft_config"]["collection"],true)
		mine_type_label.text = "NFT"
	elif data["token_config"] != null:
		mine_gate_asset = await SolanaService.asset_manager.get_asset_from_mint(data["token_config"]["spending_mint"],true)
		mine_type_label.text = "TOKEN"
	
	if mine_gate_asset!=null:
		mine_gate_displayable.set_data(mine_gate_asset)
	else:
		push_error("Mine Gate Asset Failed to load...")

	mine_timer_button.start_timer(data["time_span"]["start_time"],data["time_span"]["end_time"])
	
func select_mine() -> void:
	on_selected.emit(self)
	
func deactivate_mine() -> void:
	mine_timer_button.disabled=true
	
