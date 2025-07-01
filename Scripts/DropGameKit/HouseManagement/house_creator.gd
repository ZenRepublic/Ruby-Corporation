extends Node
class_name HouseCreator

@export var page_loader:PageLoader
@export var create_button:Button

var active_settings:DataInputSystem
var active_button:Button

signal on_house_created

func _ready() -> void:
	create_button.pressed.connect(create_house)
	
	change_settings_page(0)
	page_loader.on_page_changed.connect(change_settings_page)
	
	
func change_settings_page(page_id:int) -> void:
	if page_id >= page_loader.pages.size()-1:
		page_loader.next_page_button.visible=false
		create_button.visible=true
		active_button = create_button
	else:
		page_loader.next_page_button.visible=true
		create_button.visible=false
		active_button = page_loader.next_page_button
		
#	disable tracking of previous active settings
	if active_settings!=null:
		active_settings.on_fields_updated.disconnect(handle_input_update)
		
	active_settings = page_loader.pages[page_id] as DataInputSystem
	active_button.disabled=!active_settings.get_inputs_valid()
	active_settings.on_fields_updated.connect(handle_input_update)
	
	
func handle_input_update() -> void:
#	manager fee can't be bigger than standard fee, special case for onchain settings
	if active_settings == page_loader.pages[1]:
		var input_data:Dictionary = active_settings.get_input_data()
		if input_data["campaignManagerDiscount"] > input_data["campaignCreationFee"]:
			active_settings.get_input_field("campaignManagerDiscount").clear()

	active_button.disabled = !active_settings.get_inputs_valid()
	
func create_house() -> void:
	var uri_data:Dictionary = page_loader.pages[0].get_input_data()
	
	var upload_response:Dictionary = await RubianServer.data_uploader.upload_uri(uri_data)
	if !upload_response.has("body") or !upload_response["body"].has("url"):
		push_error("Failed To Upload offchain metadata to Turbo")
		return
	var uri_link:String = upload_response["body"]["url"]
		
		
	var house_data:Dictionary =  page_loader.pages[1].get_input_data()
	
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
	var tx_data:TransactionData = await ClubhouseProgram.create_house(house_data["houseName"],house_data["managerCollection"],house_currency,house_config,uri_link)
	
	if tx_data.is_successful():
		on_house_created.emit()
