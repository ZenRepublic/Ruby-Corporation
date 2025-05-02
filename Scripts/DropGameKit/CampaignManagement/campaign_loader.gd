extends Node
class_name CampaignLoader

@export var screen_manager:ScreenManager

@export var campaign_display_system:AccountDisplaySystem
@export var campaign_type_filter:OptionButton
@export var show_expired_filter:CheckBox

@export var campaign_interactor:CampaignInteractor

@export var vault_display:StakeTokenVault
@export var vault_button:Button

var house_pda:Pubkey

var display_filters:Dictionary

func _ready() -> void:
	set_campaign_type_filter(campaign_type_filter.get_selected_id())
	campaign_type_filter.item_selected.connect(set_campaign_type_filter)
	set_show_expired_filter()
	show_expired_filter.pressed.connect(set_show_expired_filter)
	
	vault_button.pressed.connect(show_vault_display)
	await load_campaigns()
	
func on_visibility_changed() -> void:
	if self.visible:
		pass
		
func load_campaigns() -> void:
	var house_data:Dictionary = await ClubhouseProgram.utils.get_active_house_data()
	if house_data.size()==0:
		print("No active house found. Skipping setting campaigns")
		return
		
	house_pda = ClubhousePDA.get_house_pda(house_data["house_name"])
	
	var filter:Array = [{"memcmp" : { "offset":9, "bytes": house_pda.to_string()}}]
	campaign_display_system.set_sort_data("time_span.start_time",false)
	campaign_display_system.set_list(ClubhouseProgram.get_program(),"Campaign",filter)
	campaign_display_system.on_account_selected.connect(select_campaign)
	#self.visibility_changed.connect(on_visibility_changed)
	#mine_account_display.on_account_added.connect(handle_mine_active)
	
		
func select_campaign(campaign_entry:AccountDisplayEntry) -> void:
	screen_manager.switch_active_panel(0)
	await campaign_interactor.set_campaign_data(campaign_entry.account_id,campaign_entry.data)
	screen_manager.switch_active_panel(2)
	
func set_campaign_type_filter(selected_idx:int) -> void:
	var type_name:String = campaign_type_filter.get_item_text(selected_idx)
	if type_name == "Token":
		campaign_display_system.remove_filter_parameter("nft_config")
		campaign_display_system.add_filter_parameter("token_config",null,"notEquals")
	if type_name == "NFT":
		campaign_display_system.remove_filter_parameter("token_config")
		campaign_display_system.add_filter_parameter("nft_config",null,"notEquals")
	
#	this function hits first before accounts are setup, but we also want to
#	be able to filter later on when they are all loaded
	if campaign_display_system.raw_accounts.size()>0:
		campaign_display_system.refresh_account_list(false)
	
func set_show_expired_filter() -> void:
	var show_expired:bool = show_expired_filter.button_pressed

	if show_expired:
		campaign_display_system.remove_filter_parameter("time_span.end_time")
	else:
		var curr_time = Time.get_unix_time_from_system()
		campaign_display_system.add_filter_parameter("time_span.end_time",curr_time,"higher")
		
	#	this function hits first before accounts are setup, but we also want to
#	be able to filter later on when they are all loaded
	if campaign_display_system.raw_accounts.size()>0:
		campaign_display_system.refresh_account_list(false)
	pass
	

#func handle_mine_active(mine_entry:AccountDisplayEntry) -> void:
	#var mine_start_timestamp:float = mine_entry.data["time_span"]["start_time"]
	#var mine_end_timestamp:float = mine_entry.data["time_span"]["end_time"]
	#var utc_timestamp:float = Time.get_unix_time_from_system()
#
	#mine_entry.mine_timer_button.disabled = utc_timestamp>mine_end_timestamp or utc_timestamp<mine_start_timestamp
	
func show_vault_display() -> void:
	vault_display.visible=true
	vault_display.load_vaults(false)
