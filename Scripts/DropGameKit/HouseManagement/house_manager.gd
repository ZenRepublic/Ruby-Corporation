extends Node
class_name HouseManager

@export var house_name_label:Label
@export var active_campaigns_label:Label
@export var total_campaigns_label:Label
@export var unique_players_label:NumberLabel

@export var house_fees_label:Label
@export var sol_fees_label:Label

@export var house_edit_settings:DataInputSystem

var curr_house_data:Dictionary
var decimals:int
var house_key:Pubkey

signal on_house_edited
signal on_house_closed
signal on_fees_claimed

# Called when the node enters the scene tree for the first time.
func set_house_data(id:String,data:Dictionary) -> void:
	curr_house_data = data

	house_name_label.text = data["house_name"]
	house_key = Pubkey.new_from_string(id)
	
	active_campaigns_label.text = str(data["open_campaigns"])
	total_campaigns_label.text = str(data["total_campaigns"])
	unique_players_label.set_value(data["unique_players"])
	
	var house_vault_balance:float = data["unclaimed_house_fees"]/pow(10,data["house_currency_decimals"])
	house_fees_label.text = "%s SOL" % str(house_vault_balance)
	var house_sol_fee_balance:float = data["unclaimed_sol_fees"]/pow(10,9)
	sol_fees_label.text = "%s SOL" % str(house_sol_fee_balance)
	
	await set_input_system_fields(data)
	
func set_input_system_fields(house_data:Dictionary) -> void:
	var data_to_set:Dictionary
	
	var house_config:Dictionary = house_data["config"]
	
	decimals = await SolanaService.get_token_decimals(house_data["house_currency"].to_string())
	data_to_set["oracleKey"] = house_config["oracle_key"].to_string()
	data_to_set["campaignCreationFee"] = str(house_config["campaign_creation_fee"]/pow(10,decimals))
	data_to_set["campaignManagerDiscount"] = str((house_config["campaign_creation_fee"]-house_config["campaign_manager_discount"])/pow(10,decimals))
	data_to_set["claimFee"] = str(house_config["claim_fee"]/pow(10,9))
	data_to_set["rewardsTax"] = str(house_config["rewards_tax"]/10.0)
	
	house_edit_settings.set_input_fields_data(data_to_set)
	
	
func edit_house() -> void:
	var house_data:Dictionary = house_edit_settings.get_input_data()
	var house_name:String = curr_house_data["house_name"]
	
	var oracleKey:Pubkey = house_data["oracleKey"]
	if oracleKey == null:
		oracleKey = SystemProgram.get_pid()
	
	var currency_decimals:int = decimals
	var creation_fee_lamports:int = floori(house_data["campaignCreationFee"] * pow(10,currency_decimals))
	
	var manager_discount = house_data["campaignCreationFee"] - house_data["campaignManagerDiscount"]
	var manager_discount_lamports:int = floori(manager_discount * pow(10,currency_decimals))
	var claim_fee_lamports:int =  floori(house_data["claimFee"] * pow(10,9))
	var rewards_tax_basis_points:int = house_data["rewardsTax"]*10
	
	var house_config:Dictionary = {
		"oracle_key":oracleKey,
		"campaign_creation_fee":AnchorProgram.u64(creation_fee_lamports),
		"campaign_manager_discount":AnchorProgram.u64(manager_discount_lamports),
		"claim_fee":AnchorProgram.u64(claim_fee_lamports),
		"rewards_tax":AnchorProgram.u64(rewards_tax_basis_points),
	}
	
	var tx_data:TransactionData = await ClubhouseProgram.update_house(house_name,house_config)
	
	if tx_data.is_successful():
		on_house_edited.emit()
		
func close_house() -> void:
	var house_name:String = curr_house_data["house_name"]
	var house_currency:Pubkey = curr_house_data["house_currency"]
	
	var tx_data:TransactionData = await ClubhouseProgram.close_house(house_name,house_currency)
	
	if tx_data.is_successful():
		on_house_closed.emit()
		
	
func claim_collected_fees() -> void:
	var house_name:String = curr_house_data["house_name"]
	var house_currency:Pubkey = curr_house_data["house_currency"]
	
	var tx_data:TransactionData = await ClubhouseProgram.withdraw_house_fees(house_name,house_currency)
	
	if tx_data.is_successful():
		on_fees_claimed.emit()
		house_fees_label.text = "0 SOL"
		sol_fees_label.text = "0 SOL"
	

	
