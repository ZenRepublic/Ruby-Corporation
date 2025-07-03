extends Node
class_name CampaignCreator

@export var screen_manager:ScreenManager

@export var page_loader:PageLoader
@export var create_button:Button

@export var token_selector:AssetSelector
@export var manager_selector:AssetSelector

@export var campaign_mode_button_group:ButtonGroup
@export var campaign_modes:Array[DataInputSystem]

@export var fund_input_field:InputField
@export var max_fund_button:Button
@export var burn_remainder_checkbox:CheckBox

@export var token_visuals:Array[TextureRect]

@export var creation_fee_label:NumberLabel
@export var payment_displayable:DisplayableAsset

var house_pda:Pubkey
var house_data:Dictionary

var active_settings:DataInputSystem
var active_button:Button

var selected_manager:WalletAsset
var selected_mode:DataInputSystem
var selected_token:Token

var house_currency_mint:Pubkey
var campaign_creation_fee:float
var manager_creation_fee:float

var managers_in_use:Array

var burn_remainder:bool=false

signal on_campaign_created

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_manager.switch_active_panel(0)
	
	max_fund_button.pressed.connect(set_max_fund)	
	burn_remainder_checkbox.toggled.connect(set_burn_remainder)
	token_selector.on_selected.connect(set_campaign_token)
	
	manager_selector.on_display_opened.connect(set_manager_collection_gate)
	manager_selector.on_selected.connect(update_manager_selection)
	
	campaign_mode_button_group.pressed.connect(select_campaign_mode)
	select_campaign_mode(campaign_mode_button_group.get_buttons()[0])
	
	create_button.pressed.connect(create_campaign)
			
	house_pda = ClubhouseProgram.utils.get_active_house_key()
	house_data = await ClubhouseProgram.utils.get_active_house_data()
	if house_data.size()==0:
		print("No active house found. Skipping setting up campaign creator")
		return	
		
	await setup_creator()
	
	page_loader.on_page_changed.connect(change_settings_page)
	change_settings_page(0)
	
	managers_in_use = await ClubhouseProgram.utils.get_managers_in_use(house_pda)
	update_manager_selection(null)
	
	screen_manager.switch_active_panel(1)
	
	
func setup_creator() -> void:
	var house_config:Dictionary = house_data["config"]
	house_currency_mint = house_data["house_currency"]
	var decimals = await SolanaService.get_token_decimals(house_currency_mint.to_string())
	campaign_creation_fee = house_config["campaign_creation_fee"]/pow(10,decimals)
	manager_creation_fee = (house_config["campaign_creation_fee"]-house_config["campaign_manager_discount"])/pow(10,decimals)
	
	if house_currency_mint==null:
		payment_displayable.symbol_label.text = "SOL"
	else:
		var payment_token:Token = await SolanaService.asset_manager.get_asset_from_mint(house_currency_mint)
		if payment_token!=null:
			await payment_displayable.set_data(payment_token)
	
	
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
		
#	for player settings, have to override with selected mode settings
	print(page_id)
	if page_id == 1:
		active_settings = selected_mode
		print("ACTIVATING SELECTED MODE ",selected_mode.name)
	else:
		active_settings = page_loader.pages[page_id] as DataInputSystem
		
	active_button.disabled=!active_settings.get_inputs_valid()
	active_settings.on_fields_updated.connect(handle_input_update)
	
func handle_input_update() -> void:
	active_button.disabled = !active_settings.get_inputs_valid()
	
func set_max_fund() -> void:
	fund_input_field.text = str(fund_input_field.max_value)

func set_burn_remainder(is_on:bool) -> void:
	burn_remainder = is_on
	
func set_campaign_token(selected_asset:WalletAsset) -> void:
	var new_token:Token = selected_asset as Token

	if new_token != selected_token:
		fund_input_field.clear()
	
	selected_token = new_token
	fund_input_field.max_value = await selected_token.get_balance()
	
	if selected_token.image!=null:
		for visual in token_visuals:
			visual.texture = selected_token.image

	handle_input_update()
	
func set_manager_collection_gate(display_system:AssetDisplaySystem) -> void:
	if display_system is not NFTDisplaySystem:
		push_error("NFT Display system expected, skipping collection gating")
	var manager_display_system:NFTDisplaySystem = display_system as NFTDisplaySystem
	var manager_collection_key:Pubkey = house_data["manager_collection"]
	
	var collection_filter:NFTCollection = NFTCollection.new()
	collection_filter.collection_mint = manager_collection_key
	manager_display_system.collection_filter = [collection_filter]
	
	SolanaService.asset_manager.add_collection_to_whitelist(manager_collection_key)
	manager_display_system.exception_address_list = managers_in_use
	
func select_campaign_mode(selected_button:Button) -> void:
	for mode in campaign_modes:
		mode.visible=false
		
	if active_settings!=null:
		active_settings.on_fields_updated.disconnect(handle_input_update)
		
#	0 is token mode, 1 is NFT mode
	for i in campaign_mode_button_group.get_buttons().size():
		if selected_button == campaign_mode_button_group.get_buttons()[i]:
			campaign_modes[i].visible=true
			selected_mode = campaign_modes[i]
			
			if active_settings!=null:
				active_settings.on_fields_updated.disconnect(handle_input_update)
			active_settings = campaign_modes[i]
			active_settings.on_fields_updated.connect(handle_input_update)
	
func update_manager_selection(selected_asset:WalletAsset) -> void:
	selected_manager = selected_asset
	if selected_asset == null:
		creation_fee_label.set_value(campaign_creation_fee)
	else:
		creation_fee_label.set_value(manager_creation_fee)
	
func create_campaign() -> void:
	var house_pda:Pubkey = ClubhousePDA.get_house_pda(house_data["house_name"])
	var currency_mint:Pubkey = house_data["house_currency"]
	
#	MAIN SETTINGS (1st page)
	var main_settings:Dictionary = page_loader.pages[0].get_input_data()
	
	var manager_data = null
	if main_settings["campaignManager"]!=null:
		var manager_asset:WalletAsset = main_settings["campaignManager"]
		
		manager_data={
			"asset":manager_asset.mint,
			"asset_type": 3 if manager_asset is CoreAsset else 1
		}
		
	var campaign_name:String = main_settings["campaignName"]
	
	var timespan:Dictionary = {
		"start_time":main_settings["campaignStartTime"],
		"end_time":get_campaign_end_timestamp(main_settings["campaignStartTime"],main_settings["campaignDuration"])
	}
	
	
#	PLAYER SETTINGS (2nd page)
	var player_settings:Dictionary = selected_mode.get_input_data()
	var nft_config = null
	var token_config = null
	
	if player_settings.has("collection"):
		nft_config = {
			"collection": player_settings["collection"],
			"max_player_energy":AnchorProgram.u8(player_settings["maxEnergy"]),
			"energy_recharge_minutes":AnchorProgram.option(player_settings["rechargeRate"])
		}
	elif player_settings.has("tokenMint"):
		var decimals:int = await SolanaService.get_token_decimals(player_settings["tokenMint"].to_string())
		token_config = {
			"spending_mint": player_settings["tokenMint"],
			"energy_price":AnchorProgram.u64(player_settings["energyPrice"]*pow(10,decimals)),
			"spending_mint_decimals":AnchorProgram.u8(decimals),
			"token_use":player_settings["tokenUse"]["id"]
		}
		
#	REWARD SETTINGS (3rd page)
	var reward_settings:Dictionary = page_loader.pages[2].get_input_data()
	
	var reward_mint:Pubkey = reward_settings["rewardCurrency"].mint
	
	var reward_mint_decimals:int = await SolanaService.get_token_decimals(reward_mint.to_string())
	var fund_amount_lamports:int = floori(reward_settings["fundAmount"]*pow(10,reward_mint_decimals))
	
	var max_reward_lamports:int = floori(reward_settings["maxReward"]*pow(10,reward_mint_decimals))
	var player_claim_fee: int = floori(reward_settings["rewardsTax"]*pow(10,9))
	

	var tx_data:TransactionData = await ClubhouseProgram.create_campaign(house_pda,currency_mint,campaign_name,reward_mint,fund_amount_lamports,max_reward_lamports,burn_remainder,player_claim_fee,timespan,nft_config,token_config,manager_data)
	
	if tx_data.is_successful():
		on_campaign_created.emit()
		queue_free()
		
func get_campaign_end_timestamp(start_timestamp:int,campaign_duration_in_hours:int) -> int:
	#timestamp is in seconds, so we need to convert hours to seconds and add it to the timestamp
	var duration_in_seconds:int = campaign_duration_in_hours*3600
	var end_timestamp:int = floori(start_timestamp + duration_in_seconds)
	return end_timestamp
	
	
