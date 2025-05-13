extends Node

#for building custom program instructions, first goes function name, then array of accounts
#and then variables to pass in

#IMPORTANT:
#if no variables need to be passed in, write 'null'
#if multiple variables, put them in a dictionary
#if the variable is a class, pass it in as dictionary

@onready var program:AnchorProgram = $AnchorProgram
@export var server:ClubhouseServer
@export var utils:ClubhouseUtils
@export var claimer:CampaignRewardClaimer

func get_program() -> AnchorProgram:
	return program
	
func get_pid() -> Pubkey:
		return Pubkey.new_from_string(program.get_pid())
		
func send_transaction(instructions:Array[Instruction], oracle:Pubkey=null, extra_signers:Array[Keypair]=[]) -> TransactionData:
	var tx_data:TransactionData
	
	if oracle!=null and oracle.to_string() != SystemProgram.get_pid().to_string():
		if !server.is_set():
			push_error("Oracle is needed for this transaction, but the server is missing!")
			return TransactionData.new({})

		##USER FIRST		
		#var signers:Array = [SolanaService.wallet.get_kp(),oracle]
		#var transaction:Transaction = await SolanaService.transaction_manager.create_transaction(instructions,SolanaService.wallet.get_kp())
		#transaction = await SolanaService.transaction_manager.sign_transaction_normal(transaction,signers)
		##get the signature from oracle. it returns tx_bytes. so turn to transaction again 		
		#var tx_bytes:PackedByteArray = await server.add_oracle_signature(transaction)
		#transaction.queue_free()
#
		#if tx_bytes.size()==0:
			#push_error("Failed to sign with the oracle keypair!")
			#return TransactionData.new({})
			#
		#var signed_transaction:Transaction = Transaction.new_from_bytes(tx_bytes)
		#add_child(signed_transaction)
		#signed_transaction.set_signers(signers)
		#tx_data = await SolanaService.transaction_manager.send_transaction(signed_transaction)
		
		
		#ORACLE FIRST		
		var signers:Array = [oracle,SolanaService.wallet.get_kp()]
		for extra_signer in extra_signers:
			signers.append(extra_signer.to_pubkey())
		
		var transaction:Transaction = await SolanaService.transaction_manager.create_transaction(instructions,SolanaService.wallet.get_kp())
		transaction.set_signers(signers)
		transaction.partially_sign(extra_signers)
		
		#get the signature from oracle. it returns tx_bytes. so turn to transaction again 
		var tx_bytes:PackedByteArray = await server.add_oracle_signature(transaction)
		transaction.queue_free()
		if tx_bytes.size()==0:
			push_error("Failed to sign with the oracle keypair!")
			var failed_tx:TransactionData = TransactionData.new({},{"error":"failed to receive oracle signature..."})
			SolanaService.transaction_manager.force_finish_transaction(failed_tx)
			return failed_tx
			
		var signed_transaction:Transaction = await SolanaService.transaction_manager.sign_transaction_serialized(tx_bytes,SolanaService.wallet.get_kp(),signers)
		tx_data = await SolanaService.transaction_manager.send_transaction(signed_transaction)
	else:
		var transaction:Transaction = await SolanaService.transaction_manager.create_transaction(instructions,SolanaService.wallet.get_kp())
		for extra_signer in extra_signers:
			transaction = await SolanaService.transaction_manager.add_signature(transaction,extra_signer)
		await SolanaService.transaction_manager.add_signature(transaction,SolanaService.wallet.get_kp())
		tx_data = await SolanaService.transaction_manager.send_transaction(transaction)
		
	return tx_data
		
func create_house(house_name:String,manager_collection:Pubkey,house_currency:Pubkey,house_config:Dictionary) -> TransactionData:
	var create_house_ix:Instruction = get_create_house_instruction(house_name,manager_collection,house_currency,house_config)
	var tx_data:TransactionData = await send_transaction([create_house_ix])
	return tx_data
		
func get_create_house_instruction(house_name:String,manager_collection:Pubkey,house_currency:Pubkey,house_config:Dictionary) -> Instruction:
	var house_pda:Pubkey = ClubhousePDA.get_house_pda(house_name)
	print("Creating House with ID: ",house_pda.to_string())
	var ix:Instruction = program.build_instruction("create_house",[
		SolanaService.wallet.get_kp(),
		ClubhousePDA.get_program_admin_pda(SolanaService.wallet.get_pubkey()),
		house_pda,
		ClubhousePDA.get_house_auth_pda(house_pda),
		ClubhousePDA.get_house_currency_vault(house_pda),
		SolanaService.wallet.get_pubkey(),
		house_currency,
		SolanaService.TOKEN_PID,
		SystemProgram.get_pid(),
	],{
		"manager_collection":AnchorProgram.option(manager_collection),
		"house_config": house_config,
		"house_name":house_name
	})
	return ix
	
func update_house(house_name:String,house_config:Dictionary) -> TransactionData:
	var update_house_ix:Instruction = get_update_house_instruction(house_name,house_config)
	var tx_data:TransactionData = await send_transaction([update_house_ix])
	return tx_data
	
func get_update_house_instruction(house_name:String,house_config:Dictionary) -> Instruction:
	var house_pda:Pubkey = ClubhousePDA.get_house_pda(house_name)
	
	var ix:Instruction = program.build_instruction("update_house",[
		house_pda,
		SolanaService.wallet.get_kp(),
	],{
		"house_config": house_config,
	})
	return ix
	
func close_house(house_name:String, house_currency:Pubkey) -> TransactionData:
	var close_house_ix:Instruction = get_close_house_instruction(house_name,house_currency)
	var tx_data:TransactionData = await send_transaction([close_house_ix])
	return tx_data
	
func get_close_house_instruction(house_name:String, house_currency:Pubkey) -> Instruction:
	var house_pda:Pubkey = ClubhousePDA.get_house_pda(house_name)
	var fees_withdrawal_account:Pubkey = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),house_currency)
	
	var ix:Instruction = program.build_instruction("close_house",[
		house_pda,
		SolanaService.wallet.get_kp(),
		ClubhousePDA.get_house_currency_vault(house_pda),
		fees_withdrawal_account,
		house_currency,
		SolanaService.ATA_TOKEN_PID,
		SolanaService.TOKEN_PID,
		SystemProgram.get_pid()
	],null)
	return ix
	
func withdraw_house_fees(house_name:String, house_currency:Pubkey) -> TransactionData:
	var withdraw_house_fees_ix:Instruction = get_withdraw_house_fees_instruction(house_name,house_currency)
	var tx_data:TransactionData = await send_transaction([withdraw_house_fees_ix])
	return tx_data
	
func get_withdraw_house_fees_instruction(house_name:String, house_currency:Pubkey) -> Instruction:
	var house_pda:Pubkey = ClubhousePDA.get_house_pda(house_name)
	var fees_withdrawal_account:Pubkey = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),house_currency)
	
	var ix:Instruction = program.build_instruction("withdraw_house_fees",[
		house_pda,
		SolanaService.wallet.get_kp(),
		ClubhousePDA.get_house_currency_vault(house_pda),
		fees_withdrawal_account,
		house_currency,
		SolanaService.ATA_TOKEN_PID,
		SolanaService.TOKEN_PID,
		SystemProgram.get_pid()
	],null)
	return ix

func create_campaign(house_pda:Pubkey,house_currency:Pubkey,campaign_name:String,reward_mint:Pubkey,fund_amount_lamports:int,max_reward_lamports:int,player_claim_fee:int,timespan:Dictionary,nft_config=null,token_config=null,custom_data=null) -> TransactionData:
	var campaign_keypair:Keypair = Keypair.new_random()
	var create_campaign_ix:Instruction = get_create_campaign_instruction(campaign_keypair,house_pda,house_currency,campaign_name,reward_mint,fund_amount_lamports,max_reward_lamports,player_claim_fee,timespan,nft_config,token_config,custom_data)
	var tx_data:TransactionData = await send_transaction([create_campaign_ix],null,[campaign_keypair])
	return tx_data

func get_create_campaign_instruction(campaign_keypair:Keypair,house_pda:Pubkey,house_currency:Pubkey,campaign_name:String,reward_mint:Pubkey,fund_amount_lamports:int,max_reward_lamports:int,player_claim_fee:int,timespan:Dictionary,nft_config=null,token_config=null,custom_data=null) -> Instruction:
	var campaign_key:Pubkey = campaign_keypair.to_pubkey()
	var creation_fee_account:Pubkey = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),house_currency)
	var reward_depositor_account:Pubkey = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),reward_mint)
	
	var game_mint:Pubkey = null
	var game_deposit_vault:Pubkey = null
	if token_config!=null:
		game_mint = token_config["spending_mint"]
		#for burn no deposit account. stake 0, burn 1, pay 2		
		if token_config["token_use"] != 1:
			game_deposit_vault = ClubhousePDA.get_deposit_vault_pda(campaign_key)
			
	var ix:Instruction = program.build_instruction("create_campaign",[	
		SolanaService.wallet.get_kp(),
		campaign_keypair,
		ClubhousePDA.get_campaign_auth_pda(campaign_key),
		house_pda,
		creation_fee_account,
		reward_mint,
		ClubhousePDA.get_house_currency_vault(house_pda),
		reward_depositor_account,
		ClubhousePDA.get_campaign_vault_pda(campaign_key),
		game_mint,
		game_deposit_vault,
		SolanaService.TOKEN_PID,
		SystemProgram.get_pid()
		],{
			"campaign_name":campaign_name,
			"custom_data":AnchorProgram.option(custom_data),
			"fund_amount":AnchorProgram.u64(fund_amount_lamports),
			"max_rewards_per_game":AnchorProgram.u64(max_reward_lamports),
			"player_claim_price":AnchorProgram.u64(player_claim_fee),
			"time_span":timespan,
			"nft_config":AnchorProgram.option(nft_config),
			"token_config":AnchorProgram.option(token_config)
		})
	return ix
	
func close_campaign(house_pda:Pubkey,campaign_key:Pubkey,campaign_data:Dictionary) -> TransactionData:
	var close_campaign_ix:Instruction = get_close_campaign_instruction(house_pda,campaign_key,campaign_data)
	var tx_data:TransactionData = await send_transaction([close_campaign_ix])
	
	if tx_data.is_successful() and server.is_set():
		await server.delete_campaign_data(house_pda,campaign_key)
		
	return tx_data
	
func get_close_campaign_instruction(house_pda:Pubkey,campaign_key:Pubkey,campaign_data:Dictionary) -> Instruction:
	var reward_withdrawal_account:Pubkey = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),campaign_data["reward_mint"])
	
	var game_deposit_vault:Pubkey = null
	var deposit_withdrawal_account:Pubkey = null
	var game_mint:Pubkey = null
	var deposit_token_program = null
	
	#if pay token mode, add optional accounts to claim those tokens
	if campaign_data["token_config"] != null and campaign_data["token_config"]["token_use"] == 2:
		game_deposit_vault = ClubhousePDA.get_deposit_vault_pda(campaign_key)
		deposit_withdrawal_account = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),campaign_data["token_config"]["spending_mint"])
		game_mint = campaign_data["token_config"]["spending_mint"]
		deposit_token_program = SolanaService.TOKEN_PID
		
	var ix:Instruction = program.build_instruction("close_campaign",[	
		campaign_key,
		ClubhousePDA.get_campaign_auth_pda(campaign_key),
		reward_withdrawal_account,
		campaign_data["reward_mint"],
		ClubhousePDA.get_campaign_vault_pda(campaign_key),
		house_pda,
		SolanaService.wallet.get_kp(),
		game_deposit_vault,
		deposit_withdrawal_account,
		game_mint,
		deposit_token_program,
		SolanaService.ATA_TOKEN_PID,
		SolanaService.TOKEN_PID,
		SystemProgram.get_pid()
		],null)
		
	return ix
	
func start_game(house_pda:Pubkey,oracle:Pubkey,campaign_key:Pubkey,reward_mint:Pubkey,game_data:Dictionary,force_end_previous_game:bool) -> TransactionData:
	var instructions:Array[Instruction]
	
	var start_game_ix:Instruction = get_start_game_instruction(house_pda,campaign_key,game_data)
	instructions.append(start_game_ix)
	
	var tx_data:TransactionData
	
	if force_end_previous_game:
		var unclaimed_amount = 0
		var player_id:Pubkey = game_data["asset"] if game_data.has("asset") else SolanaService.wallet.get_pubkey() 
		
		if server.is_set():
			var player_data:Dictionary = await server.get_player_data(house_pda,campaign_key,player_id)
			if player_data.has("unclaimed_amount"):
				unclaimed_amount = player_data["unclaimed_amount"]
				
		var end_game_ix:Instruction = get_claim_reward_instruction(house_pda,oracle,campaign_key,game_data,reward_mint,unclaimed_amount)
		instructions.insert(0,end_game_ix)
		tx_data = await send_transaction(instructions,oracle)
		
		if server.is_set() and tx_data.is_successful() and unclaimed_amount > 0:
			await server.set_player_data(house_pda,campaign_key,player_id,{"unclaimed_amount":0})
	else:
		tx_data = await send_transaction(instructions)
		
	return tx_data
	
func get_start_game_instruction(house_pda:Pubkey,campaign_key:Pubkey,game_data:Dictionary) -> Instruction:
	var campaign_player_pda:Pubkey
	var player_nft_token_account:Pubkey = null 
	var player_nft_metadata_account:Pubkey = null
	var core_asset_account:Pubkey=null
	var game_deposit_mint:Pubkey= null
	var player_deposit_account:Pubkey = null
	var game_deposit_vault:Pubkey = null
	
	if game_data.has("asset"):
		campaign_player_pda = ClubhousePDA.get_campaign_player_pda(campaign_key,game_data["asset"])
		if game_data["asset_type"] == 1:
			player_nft_token_account = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),game_data["asset"])
			player_nft_metadata_account = ClubhousePDA.get_nft_metadata_pda(game_data["asset"])
		elif game_data["asset_type"] == 3:
			core_asset_account = game_data["asset"]
	else:
		campaign_player_pda = ClubhousePDA.get_campaign_player_pda(campaign_key,SolanaService.wallet.get_pubkey())
		game_deposit_mint = game_data["game_mint"]
		player_deposit_account = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),game_data["game_mint"])
		if game_data["token_use"] != 1:
			game_deposit_vault = ClubhousePDA.get_deposit_vault_pda(campaign_key)
	
	var ix:Instruction = program.build_instruction("start_game",[
		house_pda,	
		campaign_key,
		SolanaService.wallet.get_kp(),
		SolanaService.TOKEN_PID,
		SystemProgram.get_pid(),
		campaign_player_pda,
		player_nft_token_account,
		player_nft_metadata_account,
		game_deposit_mint,
		player_deposit_account,
		game_deposit_vault,
		core_asset_account
		],null)
	return ix
	
	
func claim_reward(house_pda:Pubkey,oracle:Pubkey,campaign_key:Pubkey,game_data:Dictionary,reward_mint:Pubkey,reward_amount:int) -> TransactionData:
	var claim_reward_ix:Instruction = get_claim_reward_instruction(house_pda,oracle,campaign_key,game_data,reward_mint,reward_amount)
	var tx_data:TransactionData = await send_transaction([claim_reward_ix],oracle)
	
	if server.is_set():
		var unclaimed_amount = 0 
		var player_id:Pubkey = game_data["asset"] if game_data.has("asset") else SolanaService.wallet.get_pubkey()
		if !tx_data.is_successful():
			unclaimed_amount = reward_amount
		var response:Dictionary = await server.set_player_data(house_pda,campaign_key,player_id,{"unclaimed_amount":unclaimed_amount})
		
	return tx_data

func get_claim_reward_instruction(house_pda:Pubkey,oracle:Pubkey,campaign_key:Pubkey,game_data:Dictionary,reward_mint:Pubkey,reward_amount:int) -> Instruction:
	var campaign_player_pda:Pubkey
	var player_nft_token_account:Pubkey =null
	var player_nft_metadata_account:Pubkey = null
	var core_asset_account:Pubkey = null
	
	if game_data.has("asset"):
		campaign_player_pda = ClubhousePDA.get_campaign_player_pda(campaign_key,game_data["asset"])
		if game_data["asset_type"] == 1:
			player_nft_token_account = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),game_data["asset"])
			player_nft_metadata_account = ClubhousePDA.get_nft_metadata_pda(game_data["asset"])
		elif game_data["asset_type"] == 3:
			core_asset_account = game_data["asset"]
	else:
		campaign_player_pda = ClubhousePDA.get_campaign_player_pda(campaign_key,SolanaService.wallet.get_pubkey())
		
	var player_reward_token_account:Pubkey = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),reward_mint)		
	#if oracle is not set, it is defaulted to SystemProgram. We set it to null then to not need a signer	
	if oracle!=null and oracle.to_string() == SystemProgram.get_pid().to_string():
		oracle = null
	
	var ix:Instruction = program.build_instruction("end_game",[
		house_pda,	
		campaign_key,
		ClubhousePDA.get_campaign_auth_pda(campaign_key),
		campaign_player_pda,
		player_nft_token_account,
		player_nft_metadata_account,
		core_asset_account,
		reward_mint,
		ClubhousePDA.get_campaign_vault_pda(campaign_key),
		player_reward_token_account,
		SolanaService.wallet.get_kp(),
		oracle,
		SolanaService.ATA_TOKEN_PID,
		SolanaService.TOKEN_PID,
		SystemProgram.get_pid()
		],{
			"amount_won":AnchorProgram.u64(reward_amount)
		})
	return ix
	
	
func withdraw_stake(campaign_key:Pubkey,campaign_player_pda:Pubkey,game_deposit_mint:Pubkey) -> TransactionData:
	var withdraw_stake_ix:Instruction = get_withdraw_stake_instruction(campaign_key,campaign_player_pda,game_deposit_mint)
	var tx_data:TransactionData = await send_transaction([withdraw_stake_ix])
	return tx_data
	
func get_withdraw_stake_instruction(campaign_key:Pubkey,campaign_player_pda:Pubkey,game_deposit_mint:Pubkey) -> Instruction:
	var stake_recipient_ata:Pubkey = Pubkey.new_associated_token_address(SolanaService.wallet.get_pubkey(),game_deposit_mint)
	var ix:Instruction = program.build_instruction("claim_stake",[	
		campaign_player_pda,
		SolanaService.wallet.get_kp(),
		ClubhousePDA.get_campaign_auth_pda(campaign_key),
		ClubhousePDA.get_deposit_vault_pda(campaign_key),
		stake_recipient_ata,
		game_deposit_mint,
		SolanaService.ATA_TOKEN_PID,
		SolanaService.TOKEN_PID,
		SystemProgram.get_pid()
		],null)
		
	return ix
