extends Node
class_name CampaignCreator

@export var general_settings:DataInputSystem
@export var player_settings_manager:TabContainer
@export var player_settings:Array[DataInputSystem]

@export var token_selector:AssetSelector
@export var manager_selector:AssetSelector

@export var fund_input_field:InputField
@export var max_fund_button:Button

@export var token_visuals:Array[TextureRect]

@export var fee_explanation:Label
@export var creation_fee_label:Label

@export var input_submit_button:BaseButton

var selected_token:Token

var mine_creation_fee:float
var manager_creation_fee:float

var house_data:Dictionary

signal on_campaign_created

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	max_fund_button.pressed.connect(set_max_fund)	
	token_selector.on_selected.connect(set_mine_token)
	manager_selector.on_selected.connect(update_manager_selection)
	
	if input_submit_button!=null:
		input_submit_button.pressed.connect(create_campaign)
		input_submit_button.disabled=true
		general_settings.on_fields_updated.connect(handle_input_update)
		for input_system in player_settings:
			input_system.on_fields_updated.connect(handle_input_update)
	
func setup_creator(data:Dictionary) -> void:
	house_data = data
	var house_config:Dictionary = house_data["config"]
	var decimals = await SolanaService.get_token_decimals(house_data["house_currency"].to_string())
	mine_creation_fee = house_config["campaign_creation_fee"]/pow(10,decimals)
	manager_creation_fee = (house_config["campaign_creation_fee"]-house_config["campaign_manager_discount"])/pow(10,decimals)
	update_manager_selection(null)
	
	var claim_tax_percentage:float = house_config["rewards_tax"]/10.0
	fee_explanation.text = "*Fees claimable after campaign has finished. House Tax of %s%% is applied!" % str(claim_tax_percentage)
	
	
func handle_input_update() -> void:
	if input_submit_button!=null:
		if !general_settings.get_inputs_valid():
			input_submit_button.disabled = true
			return
		if !player_settings[player_settings_manager.current_tab].get_inputs_valid():
			input_submit_button.disabled = true
			return
			
		input_submit_button.disabled = false
		
func get_player_settings() -> DataInputSystem:
	return player_settings[player_settings_manager.current_tab]
	
func set_max_fund() -> void:
	fund_input_field.text = str(fund_input_field.max_value)
	
func set_mine_token(selected_asset:WalletAsset) -> void:
	var new_token:Token = selected_asset as Token

	if new_token != selected_token:
		fund_input_field.clear()
	
	selected_token = new_token
	fund_input_field.max_value = await selected_token.get_balance()
	
	if selected_token.image!=null:
		for visual in token_visuals:
			visual.texture = selected_token.image

	handle_input_update()
	
func update_manager_selection(selected_asset:WalletAsset) -> void:
	if selected_asset == null:
		creation_fee_label.text = "%s SOL" % str(mine_creation_fee)
		return
	
	var manager_fee_text:String = "FREE" if manager_creation_fee==0 else "%s SOL" % str(manager_creation_fee)
	creation_fee_label.text = manager_fee_text
	
func create_campaign() -> void:
	var general_data:Dictionary = general_settings.get_input_data()
	var house_pda:Pubkey = ClubhousePDA.get_house_pda(house_data["house_name"])
	var currency_mint:Pubkey = house_data["house_currency"]
	var campaign_name:String = general_data["campaignName"]
	var reward_mint:Pubkey = general_data["rewardCurrency"]
	
	var reward_mint_decimals:int = await SolanaService.get_token_decimals(reward_mint.to_string())
	var fund_amount_lamports:int = floori(general_data["fundAmount"]*pow(10,reward_mint_decimals))
	
	var max_reward_lamports:int = floori(general_data["maxReward"]*pow(10,reward_mint_decimals))
	var player_claim_fee: int = floori(general_data["rewardsTax"]*pow(10,9))
	
	var timespan:Dictionary = {
		"start_time":general_data["campaignStartTime"],
		"end_time":get_campaign_end_timestamp(general_data["campaignStartTime"],general_data["campaignDuration"])
	}
	
	var player_data:Dictionary = get_player_settings().get_input_data()
	var nft_config = null
	var token_config = null
	
	if player_data.has("collection"):
		nft_config = {
			"collection": player_data["collection"],
			"max_player_energy":AnchorProgram.u8(player_data["maxEnergy"]),
			"energy_recharge_minutes":AnchorProgram.option(player_data["rechargeRate"])
		}
	elif player_data.has("tokenMint"):
		var decimals:int = await SolanaService.get_token_decimals(player_data["tokenMint"].to_string())
		token_config = {
			"spending_mint": player_data["tokenMint"],
			"energy_price":AnchorProgram.u64(player_data["energyPrice"]*pow(10,decimals)),
			"spending_mint_decimals":AnchorProgram.u8(decimals),
			"token_use":player_data["tokenUse"]["id"]
		}
		#print(token_config)
		#return

	var tx_data:TransactionData = await ClubhouseProgram.create_campaign(house_pda,currency_mint,campaign_name,reward_mint,fund_amount_lamports,max_reward_lamports,player_claim_fee,timespan,nft_config,token_config)
	
	if tx_data.is_successful():
		on_campaign_created.emit()
		
func get_campaign_end_timestamp(start_timestamp:int,campaign_duration_in_hours:int) -> int:
	#timestamp is in seconds, so we need to convert hours to seconds and add it to the timestamp
	var duration_in_seconds:int = campaign_duration_in_hours*3600
	var end_timestamp:int = floori(start_timestamp + duration_in_seconds)
	return end_timestamp
	
