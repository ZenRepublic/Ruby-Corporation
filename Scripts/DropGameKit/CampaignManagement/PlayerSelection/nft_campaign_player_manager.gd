extends CampaignPlayerManager
class_name NFTCampaignPlayerManager

@export var player_select_system:AssetDisplaySystem
@export var player_container:Control
@export var displayable_player:DisplayableAsset
@export var energy_bar:ProgressBar
@export var energy_bar_label:Label
@export var recharge_timed_button:TimedButton

@export var play_button:ButtonLock

var selected_player:WalletAsset

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if recharge_timed_button!=null:
		recharge_timed_button.on_timer_finished.connect(display_player_energy)
	if player_select_system!=null:
		player_select_system.on_asset_selected.connect(select_player)
		
	play_button.pressed.connect(start_game)
	
func setup_player_selection(campaign:Pubkey,data:Dictionary) -> void:
	super.setup_player_selection(campaign,data)
	
	if player_select_system!=null:
		if player_container!=null:
			player_container.visible=false
		var collection_mint:Pubkey = data["nft_config"]["collection"]
		
		var collection_filter:NFTCollection = NFTCollection.new()
		collection_filter.collection_mint = collection_mint
		player_select_system.collection_filter = [collection_filter]
		
		SolanaService.asset_manager.add_collection_to_whitelist(collection_mint)
		player_select_system.load_all_owned_assets()
	
	
func select_player(asset:WalletAsset) -> void:
	if asset == null:
		print("cant select player, because provided asset is null")
		return
		
	selected_player = asset
	curr_player_data = await get_player_data(selected_player)
	print(curr_player_data)
	var max_energy:int = campaign_data["nft_config"]["max_player_energy"]
	energy_bar.max_value = max_energy
	
	await displayable_player.set_data(asset)
	display_player_energy()
	
	if player_container!=null:
		player_container.visible=true
	
func display_player_energy() -> void:
	#if going to play for first time, the dictionary will be fake, missing "energy". check get_player_data function
	if curr_player_data.size() == 0 or !curr_player_data.has("energy"):
		energy_bar.value = energy_bar.max_value
		recharge_timed_button.visible = false
	elif campaign_data["nft_config"]["energy_recharge_minutes"] == null:
		energy_bar.value = curr_player_data["energy"]
		recharge_timed_button.visible = false
	else:
		var remaining_energy:int = curr_player_data["energy"]
		var time_charging:float = Time.get_unix_time_from_system() - curr_player_data["recharge_start_time"]
		#timestamps are in seconds, so multiplying minutes should do the job
		var energy_recharge_timestamp:int = campaign_data["nft_config"]["energy_recharge_minutes"] * 60
		var energy_charged:int = floori(time_charging/energy_recharge_timestamp)
		energy_bar.value = clamp(remaining_energy+energy_charged,0,energy_bar.max_value)
		
		recharge_timed_button.visible = energy_bar.value < energy_bar.max_value
		if recharge_timed_button.visible:
			var time_to_next_energy = energy_recharge_timestamp - int(time_charging) % energy_recharge_timestamp
			var curr_time:float = Time.get_unix_time_from_system()
			recharge_timed_button.start_timer(curr_time, curr_time + time_to_next_energy)
			
	energy_bar_label.text = "%s/%s" % [int(energy_bar.value),int(energy_bar.max_value)]
	
	if energy_bar.value<=0:
		play_button.disabled = true
		play_button.text = "Enter Mine!"
	else:
		play_button.lock_active=true
		play_button.try_unlock()
	
func get_player_nft() -> Pubkey:
	return selected_player.mint
	

func get_player_data(player_asset:WalletAsset) -> Dictionary:
	var campaign_player_pda:Pubkey = ClubhousePDA.get_campaign_player_pda(campaign_key,player_asset.mint)
	var player_data:Dictionary =  await SolanaService.fetch_program_account_of_type(ClubhouseProgram.get_program(),"CampaignPlayer",campaign_player_pda)
	if player_data.size()==0:
		#if there's no data, means fresh account
		var identity_type:int = 1
		if player_asset is CoreAsset:	
			identity_type = 3
			
		player_data = {
			"player_identity":{"identity_type":identity_type,"pubkey":player_asset.mint},
			"in_game":false
		}
			

	return player_data
	
func start_game() -> void:
#	refresh data just in case
	curr_player_data = await get_player_data(selected_player)
	
	var reward_mint:Pubkey = campaign_data["reward_mint"]
	var house_data:Dictionary = await ClubhouseProgram.utils.get_house_data(campaign_data["house"])
	var oracle:Pubkey = house_data["config"]["oracle_key"]
	
	var game_data:Dictionary = {
		"asset":curr_player_data["player_identity"]["pubkey"],
		"asset_type": curr_player_data["player_identity"]["identity_type"]
	}
	var force_end_previous_game:bool = curr_player_data["in_game"]
	print("Entering game with asset: ",game_data["asset"].to_string())
	#multi instruction doesn't work. signing 2 transactions instead temporarily	
	#if force_end_previous_game:
		#var end_game_tx_data:TransactionData = await ClubhouseProgram.claim_reward(campaign_data["house"],oracle,campaign_key,game_data,reward_mint,0)
		#if !end_game_tx_data.is_successful():
			#return
		#force_end_previous_game=false
	
	var tx_data:TransactionData = await ClubhouseProgram.start_game(campaign_data["house"],oracle,campaign_key,reward_mint,game_data,force_end_previous_game)
	if tx_data.is_successful():
		on_game_started.emit(campaign_key,campaign_data,curr_player_data)
