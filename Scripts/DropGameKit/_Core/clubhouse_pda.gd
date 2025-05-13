extends Node
class_name ClubhousePDA

static var PROGRAM_ID:Pubkey = Pubkey.new_from_string("C1ubv5AC5w7Eh3iHpEt2BXZ1g3eARQtMRgmE2AXfznSg")
	
static func get_house_pda(house_name:String) -> Pubkey:
	var name_bytes = "house".to_utf8_buffer()
	var house_name_bytes = house_name.to_utf8_buffer()
	return Pubkey.new_pda_bytes([name_bytes,house_name_bytes],PROGRAM_ID)
	
static func get_house_auth_pda(house_key:Pubkey) -> Pubkey:
	return Pubkey.new_pda_bytes([house_key.to_bytes()],PROGRAM_ID)	
	
static func get_program_admin_pda(admin_key:Pubkey) -> Pubkey:
	var name_bytes = "program_admin".to_utf8_buffer()
	return Pubkey.new_pda_bytes([name_bytes,admin_key.to_bytes()],PROGRAM_ID)

static func get_house_currency_vault(house_pda:Pubkey) -> Pubkey:
	var name_bytes = "vault".to_utf8_buffer()
	return Pubkey.new_pda_bytes([name_bytes,house_pda.to_bytes()],PROGRAM_ID)

static func get_campaign_auth_pda(campaign_key:Pubkey) -> Pubkey:
	return Pubkey.new_pda_bytes([campaign_key.to_bytes()],PROGRAM_ID)	
	
static func get_campaign_vault_pda(campaign_key:Pubkey) -> Pubkey:
	var name_bytes = "rewards".to_utf8_buffer()
	return Pubkey.new_pda_bytes([name_bytes,campaign_key.to_bytes()],PROGRAM_ID)
	
static func get_deposit_vault_pda(campaign_key:Pubkey) -> Pubkey:
	var name_bytes = "player_deposit".to_utf8_buffer()
	return Pubkey.new_pda_bytes([name_bytes,campaign_key.to_bytes()],PROGRAM_ID)
	
static func get_campaign_player_pda(campaign_key:Pubkey,player_mint:Pubkey) -> Pubkey:
	var name_bytes = "player".to_utf8_buffer()
	return Pubkey.new_pda_bytes([name_bytes,campaign_key.to_bytes(),player_mint.to_bytes()],PROGRAM_ID)
	
static func get_nft_metadata_pda(nft:Pubkey) -> Pubkey:
	var name_bytes = "metadata".to_utf8_buffer()
	var metadata_pid_seed:PackedByteArray = SolanaUtils.bs58_decode(SolanaService.TOKEN_METADATA_PID)
	return Pubkey.new_pda_bytes([name_bytes,metadata_pid_seed,nft.to_bytes()],Pubkey.new_from_string(SolanaService.TOKEN_METADATA_PID))
