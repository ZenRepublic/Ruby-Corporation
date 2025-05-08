extends Node
class_name HouseCreator

@export var house_settings:DataInputSystem
@export var input_submit_button:BaseButton

signal on_house_created

func _ready() -> void:
	if input_submit_button!=null:
		input_submit_button.pressed.connect(create_house)
		input_submit_button.disabled=true
		house_settings.on_fields_updated.connect(handle_input_update)

func handle_input_update() -> void:
#	manager fee can't be bigger than standard fee
	var input_data:Dictionary = house_settings.get_input_data()
	if input_data["campaignManagerDiscount"] > input_data["campaignCreationFee"]:
		house_settings.get_input_field("campaignManagerDiscount").clear()

	input_submit_button.disabled = !house_settings.get_inputs_valid()
	
func create_house() -> void:
	var house_data:Dictionary = house_settings.get_input_data()
	
	var house_currency:Pubkey = house_data["houseCurrency"]
	if house_currency == null:
		house_currency = Pubkey.new_from_string(SolanaService.WRAPPED_SOL_CA)
	var currency_decimals:int = await SolanaService.get_token_decimals(house_currency.to_string())
		
	var oracleKey:Pubkey = house_data["oracleKey"]
	if oracleKey == null:
		oracleKey = SystemProgram.get_pid()
	
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
	var tx_data:TransactionData = await ClubhouseProgram.create_house(house_data["houseName"],house_data["managerCollection"],house_currency,house_config)
	
	if tx_data.is_successful():
		on_house_created.emit()
