extends Node
class_name StakeTokenVault

@export var vault_display_system:AccountDisplaySystem

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vault_display_system.on_account_selected.connect(withdraw_stake)
	load_vaults()
	pass # Replace with function body.


func load_vaults(amount_to_load:int=100) -> void:
   #offset 8 by default (bump), and 1 for identity type. Also get only players from specific house
	var filter:Array = [
		{"memcmp" : { "offset":9, "bytes": SolanaService.wallet.get_pubkey().to_string()}},
		#{"memcmp" : { "offset":73, "bytes": ClubhouseProgram.utils.get_active_house_key().to_string()}}
	]	
	#vault_display_system.set_sort_data("time_span.start_time",false,amount_to_load)
	vault_display_system.set_list(ClubhouseProgram.get_program(),"CampaignPlayer",filter,amount_to_load,false)
	vault_display_system.refresh_account_list()
	
	
func withdraw_stake(selected_vault:StakeVaultEntry) -> void:
	var player_campaign_pda:Pubkey = Pubkey.new_from_string(selected_vault.account_id)
	var player_data:Dictionary = selected_vault.data
	print(player_data)
	print(player_data["campaign"].to_string())
	var tx_data:TransactionData = await ClubhouseProgram.withdraw_stake(player_data["campaign"],player_campaign_pda,player_data["stake_info"]["staked_mint"])
	
	if tx_data.is_successful():
		load_vaults()
	
func close() -> void:
	queue_free()
