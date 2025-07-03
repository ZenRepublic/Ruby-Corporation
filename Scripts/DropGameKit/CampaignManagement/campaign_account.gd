extends AccountDisplayEntry
class_name CampaignAccount

@export var campaign_name_label:Label

@export var asset_gate_displayable:DisplayableAsset
@export var reward_displayable:DisplayableAsset

@export var timer_button:TimedButton

func _ready() -> void:
	timer_button.on_timer_finished.connect(deactivate_campaign)
	timer_button.pressed.connect(select_campaign)

func setup_account_entry(id:String,account_data:Dictionary,index:int) -> void:
	super.setup_account_entry(id,account_data,index)
	campaign_name_label.text = account_data["campaign_name"]
	timer_button.disabled=true
	
	var house_data:Dictionary = await ClubhouseProgram.utils.get_active_house_data()
	if house_data.size()==0:
		print("No active house found. Skipping setting account entry")
		return
		
	var campaign_key:Pubkey = Pubkey.new_from_string(id)
	
	var gate_asset:WalletAsset
	if data["nft_config"] != null:
		gate_asset = await SolanaService.asset_manager.get_asset_from_mint(data["nft_config"]["collection"],true)
	elif data["token_config"] != null:
		gate_asset = await SolanaService.asset_manager.get_asset_from_mint(data["token_config"]["spending_mint"],true)
	
	if gate_asset!=null:
		await asset_gate_displayable.set_data(gate_asset)
	else:
		push_error("Gate Asset Failed to load...")
	
	var reward_token:Token = await SolanaService.asset_manager.get_asset_from_mint(data["reward_mint"],true)
	reward_token.token_account = ClubhousePDA.get_campaign_vault_pda(campaign_key)
	reward_token.decimals = data["reward_mint_decimals"]
	await reward_displayable.set_data(reward_token)

	timer_button.start_timer(data["time_span"]["start_time"],data["time_span"]["end_time"])
	
func select_campaign() -> void:
	on_selected.emit(self)
	
func deactivate_campaign() -> void:
	timer_button.disabled=true
	
