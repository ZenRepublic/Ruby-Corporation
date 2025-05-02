extends AccountDisplayEntry

@export var rank_visual:TextureRect
@export var rank_id:Label
@export var top_rank_textures:Array[Texture2D]
@export var player_displayable:DisplayableAsset
@export var token_visual:TextureRect
@export var player_score:NumberLabel
@export var copy_address_button:BaseButton

var player_address:Pubkey

func setup_account_entry(id:String,account_data:Dictionary,index:int) -> void:
	super.setup_account_entry(id,account_data,index)
	
	if index < top_rank_textures.size():
		rank_id.visible = false
		rank_visual.texture = top_rank_textures[index]
	else:
		rank_id.visible = true
		#adding one because IDs start with 0		
		rank_id.text = "%s." % str(index+1)
	
	if account_data["player_identity"]["identity_type"] == 1 or account_data["player_identity"]["identity_type"] == 3:
		var mint:Pubkey = account_data["player_identity"]["pubkey"]
		var player_asset:WalletAsset = await SolanaService.asset_manager.get_asset_from_mint(mint,true)
		await player_displayable.set_data(player_asset)
		player_address = player_asset.get_asset_owner()
		
	elif account_data["player_identity"]["identity_type"] == 2:
		player_address = account_data["player_identity"]["pubkey"]
		player_displayable.visual.visible=false
		player_displayable.name_label.text = SolanaService.wallet.get_shorthand_address(player_address)
	
	player_score.set_value(account_data["rewards_claimed"])
	

func show_copy_button(show:bool) -> void: 
	if copy_address_button==null:
		return
	copy_address_button.visible = show

func copy_holder_wallet_address() -> void:
	DisplayServer.clipboard_set(player_address.to_string())
	pass
