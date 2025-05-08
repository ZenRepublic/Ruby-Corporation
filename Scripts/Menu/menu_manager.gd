extends Node
class_name MenuManager

@export var screen_manager:ScreenManager

@export var game_selector:GameSelector
@export var campaign_loader:CampaignLoader

# Called when the node enters the scene tree for the first time.

func _init() -> void:
	add_to_group("MenuManager")
	
func _ready() -> void:
	MusicManager.play_song("Menu")
	print(game_selector)
	game_selector.on_game_selected.connect(handle_game_selection)
	campaign_loader.campaign_interactor.on_game_started.connect(load_game)
	
	if SolanaService.wallet.is_logged_in():
		handle_user_login()
	else:
		SolanaService.wallet.on_login_success.connect(handle_user_login)
		
func handle_user_login() -> void:
	pass
	
func handle_game_selection(_game_selected:DropGame) -> void:
	screen_manager.switch_active_panel(1)
	campaign_loader.load_campaigns()

func play_ui_sound(sound_name:String) -> void:
	MusicManager.play_sound(sound_name)
	
	
func load_game(campaign_key:Pubkey,campaign_data:Dictionary,player_data:Dictionary) -> void:
	MusicManager.play_sound("ButtonSimple")
	SceneManager.load_scene(game_selector.active_game.game_scene_path,true,-1,0.2,{
		"FreePlay":false,
		"CampaignKey":campaign_key,
		"CampaignData":campaign_data,
		"PlayerData":player_data
		})
		
func load_game_free_mode() -> void:
	MusicManager.play_sound("ButtonSimple")
	SceneManager.load_scene(game_selector.active_game.game_scene_path,true,-1,0.0,{"FreePlay":true})
