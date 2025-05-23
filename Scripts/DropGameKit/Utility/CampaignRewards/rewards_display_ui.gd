extends Node
class_name CampaignRewardDisplay

@export var screen_manager:ScreenManager
@export var player_visual:TextureRect
@export var visual_border:TextureRect
@export var token_visual:TextureRect
@export var amount_earned_label:NumberLabel

@export var nft_player_manager:NFTCampaignPlayerManager
@export var token_player_manager:TokenCampaignPlayerManager

var player_manager:CampaignPlayerManager
var reward_claimer:CampaignRewardClaimer

@export var return_button:BaseButton
@export var save_button:BaseButton

signal on_replay_pressed(campaign_key:Pubkey,campaign_data:Dictionary,player_data:Dictionary)
signal on_return_pressed()

func _ready() -> void:
	nft_player_manager.visible=false
	token_player_manager.visible=false
	
	save_button.pressed.connect(save_image)
	save_button.disabled=true
	return_button.pressed.connect(handle_return)
	
	reward_claimer = ClubhouseProgram.claimer


func setup_rewards_display() -> void:
	screen_manager.switch_active_panel(0)
#	to do: handle replay for token campaign
	if reward_claimer.player_data["player_identity"]["identity_type"] == 1 or reward_claimer.player_data["player_identity"]["identity_type"] == 3:
		await setup_nft_campaign_display()
	elif reward_claimer.player_data["player_identity"]["identity_type"] == 2:
		await setup_token_campaign_display()
		
	token_visual.texture = reward_claimer.campaign_token.image
	var total_earned = player_manager.curr_player_data["rewards_claimed"]/pow(10,reward_claimer.campaign_data["reward_mint_decimals"])
	amount_earned_label.set_value(total_earned)
	
	save_button.disabled=false
	screen_manager.switch_active_panel(1)
	
func setup_nft_campaign_display() -> void:
	nft_player_manager.visible=true
	player_manager = nft_player_manager
	player_manager.on_game_started.connect(handle_replay)
	
	var player_mint:Pubkey = reward_claimer.player_data["player_identity"]["pubkey"]
	var player_asset:WalletAsset = await SolanaService.asset_manager.get_asset_from_mint(player_mint)
	nft_player_manager.setup_player_selection(reward_claimer.campaign_key,reward_claimer.campaign_data)
	await nft_player_manager.select_player(player_asset)
	
func setup_token_campaign_display() -> void:
	token_player_manager.visible=true
	player_manager = token_player_manager
	player_manager.on_game_started.connect(handle_replay)
	
	await token_player_manager.setup_player_selection(reward_claimer.campaign_key,reward_claimer.campaign_data)
	pass
	
	
func save_image() -> void:
	var tex_combiner:TextureCombiner = TextureCombiner.new(player_visual,Vector2(1024,1024))
	add_child(tex_combiner)
	tex_combiner.add_visual_layer(visual_border)
	tex_combiner.add_visual_layer(token_visual)
	await tex_combiner.add_label_layer(amount_earned_label)
	var image:Image = tex_combiner.get_combined_image()
	
	if OS.has_feature("web"):
		var buffer:PackedByteArray = image.save_png_to_buffer()
		JavaScriptBridge.download_buffer(buffer, "%s.png" % "mine_reward_card", "image/png")
		
	tex_combiner.queue_free()
	
	
func handle_replay(campaign_key:Pubkey,campaign_data:Dictionary,player_data:Dictionary) -> void:
	on_replay_pressed.emit(campaign_key,campaign_data,player_data)
	
func handle_return() -> void:
	on_return_pressed.emit()
	
	
