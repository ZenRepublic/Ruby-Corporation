extends Node
class_name ClubhouseUtils

@export var devnet_house_id:String
@export var mainnet_house_id:String
var active_house_data:Dictionary

var active_house_id:String

func _ready() -> void:
	set_house_data(mainnet_house_id,devnet_house_id)
		
func get_active_house_key() -> Pubkey:
	return Pubkey.new_from_string(active_house_id)
	
func set_house_data(mainnet_id:String, devnet_id:String) -> void:
	devnet_house_id = devnet_id
	mainnet_house_id = mainnet_id
	print(devnet_house_id)
	
	if SolanaService.rpc_cluster == SolanaService.RpcCluster.MAINNET:
		active_house_id = mainnet_house_id
	elif SolanaService.rpc_cluster == SolanaService.RpcCluster.DEVNET:
		active_house_id = devnet_house_id
	
#	clear if changing house ID
	active_house_data.clear()
		
func get_active_house_data() -> Dictionary:
	if active_house_id == "":
		print("NO ACTIVE HOUSE IN CLUBHOUSE SETTINGS")
		return {}
		
	if active_house_data.size() > 0:
		return active_house_data
	
	var house_pda:Pubkey = Pubkey.new_from_string(active_house_id)
	active_house_data = await get_house_data(house_pda)
	return active_house_data

func get_house_data(house_pda:Pubkey) -> Dictionary:
	var house_data:Dictionary = await SolanaService.fetch_program_account_of_type(ClubhouseProgram.get_program(),"House",house_pda)
	if house_data.size() == 0:
		print("FAILED TO FETCH HOUSE DATA!!")
		return {}
	return house_data
	
var admin_list:Array[Pubkey]
func get_program_admin_list(fetch_new:bool=false) -> Array[Pubkey]:
	if !fetch_new and admin_list.size() > 0:
		return admin_list
		
	var result:Dictionary = await SolanaService.fetch_all_program_accounts_of_type(ClubhouseProgram.get_program(),"ProgramAdminProof",[])
	admin_list.clear()
	for key in result.keys():
		var admin_data:Dictionary = result[key]
		admin_list.append(admin_data["program_admin"])
	return admin_list
	
func get_campaign_player_data_from_nft_mint(nft_mint:Pubkey,campaign_key:Pubkey) -> Dictionary:
	var filter:Array = [
		{"memcmp" : { "offset":8, "bytes": nft_mint.to_string()}},
		{"memcmp" : { "offset":40, "bytes": campaign_key.to_string()}}
	]
	var result:Dictionary = await SolanaService.fetch_all_program_accounts_of_type(ClubhouseProgram.get_program(),"CampaignPlayer",filter)
	return result
