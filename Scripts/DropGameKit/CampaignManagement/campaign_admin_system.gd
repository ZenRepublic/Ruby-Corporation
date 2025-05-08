extends Node
class_name CampaignAdminSystem

@export var screen_manager:ScreenManager
@export var campaign_selector:AccountDisplaySystem
@export var campaign_creator:CampaignCreator
@export var campaign_manager:CampaignManager
@export var create_new_campaign_button:ButtonLock

var house_data:Dictionary

func _ready() -> void:
	campaign_creator.on_campaign_created.connect(handle_campaign_create)
	campaign_manager.on_campaign_closed.connect(handle_campaign_close)
	
	await load_owned_campaigns()
	campaign_selector.refresh_account_list()
	
	var program_admins:Array[Pubkey] = await ClubhouseProgram.utils.get_program_admin_list()
	create_new_campaign_button.set_address_list(program_admins)
		
func load_owned_campaigns() -> void:
	house_data = await ClubhouseProgram.utils.get_active_house_data()
	if house_data.size()==0:
		print("No active house found. Skipping setting up campaign creator")
		return
	
	await campaign_creator.setup_creator(house_data)
	var house_pda:Pubkey = ClubhousePDA.get_house_pda(house_data["house_name"])	
#	offset 9 because house is second parameter, going after bump u8, which is 8 bytes
# 	another filter is get all by creator. offset 41, because third parameter after house 32 bytes
	var filter:Array = [
		{"memcmp" : { "offset":9, "bytes": house_pda.to_string()}},
		{"memcmp" : { "offset":41, "bytes": SolanaService.wallet.get_pubkey().to_string()}}
	]	
	campaign_selector.set_list(ClubhouseProgram.get_program(),"Campaign",filter,10,false)
	
	campaign_selector.on_account_selected.connect(load_campaign)

	
func load_campaign(selected_entry:AccountDisplayEntry) -> void:
	screen_manager.switch_active_panel(0)
	await campaign_manager.set_campaign(selected_entry.account_id,selected_entry.data)
	screen_manager.switch_active_panel(2)

func handle_campaign_create() -> void:
	campaign_selector.refresh_account_list()
	screen_manager.switch_active_panel(1)
	
func handle_campaign_close() -> void:
	campaign_selector.refresh_account_list()
	screen_manager.switch_active_panel(1)
	
func close() -> void:
	queue_free()
