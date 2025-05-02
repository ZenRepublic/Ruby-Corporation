extends AccountDisplayEntry
class_name StakeVaultEntry

@export var campaign_name_label:Label
@export var stake_token_displayable:DisplayableAsset

@export var stake_amount_label:NumberLabel
@export var withdraw_button:TimedButton

var stake_data:Dictionary

func _ready() -> void:
	withdraw_button.on_timer_finished.connect(activate_withdraw)
	withdraw_button.pressed.connect(handle_select)
	

func setup_account_entry(id:String,account_data:Dictionary,index:int) -> void:
	super.setup_account_entry(id,account_data,index)
	
	withdraw_button.disabled=true
	
#	if refreshed right after claiming, this account may still be up but empty
#	in that case ignore
	if account_data.size() == 0 or account_data["stake_info"] == null:
		self.visible=false
		return
	
	stake_data = account_data["stake_info"]
		
	campaign_name_label.text = stake_data["campaign_name"]
	
	var stake_token:Token = await SolanaService.asset_manager.get_asset_from_mint(stake_data["staked_mint"],true)
	await stake_token_displayable.set_data(stake_token)
	stake_amount_label.set_value(stake_data["amount"]/pow(10, stake_data["staked_mint_decimals"]))
	
	withdraw_button.start_timer(Time.get_unix_time_from_system(),stake_data["campaign_end_time"])
	
func activate_withdraw() -> void:
	withdraw_button.disabled = false
	pass
	
func handle_select() -> void:
	on_selected.emit(self)
	pass
	
