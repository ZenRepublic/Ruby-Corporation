extends Node
class_name MenuManager

@export var screen_manager:ScreenManager

@export var gig_manager:GigManager
@export var campaign_loader:CampaignLoader

@export var music_library:Dictionary
@export var sfx_manager:SFXManager

# Called when the node enters the scene tree for the first time.

func _init() -> void:
	add_to_group("MenuManager")
	
func _ready() -> void:
	MusicManager.play_song(music_library["Menu"])
	gig_manager.on_gig_selected.connect(handle_gig_selection)
	campaign_loader.campaign_interactor.on_game_started.connect(load_gig)
	
	if SolanaService.wallet.is_logged_in():
		handle_user_login()
	else:
		SolanaService.wallet.on_login_success.connect(handle_user_login)
		
func handle_user_login() -> void:
	pass
	
func handle_gig_selection(selected_gig:ClubhouseGig) -> void:
	screen_manager.switch_active_panel(1)
	campaign_loader.load_campaigns()

func play_ui_sound(sound_name:String) -> void:
	sfx_manager.play_sound(sound_name)
	
	
func load_gig(campaign_key:Pubkey,campaign_data:Dictionary,player_data:Dictionary) -> void:
	play_ui_sound("ButtonSimple")
	var scene_to_load = await gig_manager.load_active_gig_and_get_scene()
	print(scene_to_load)
	if scene_to_load!=null:
		SceneManager.load_scene(scene_to_load,true,-1,0.8,{
			"FreePlay":false,
			"CampaignKey":campaign_key,
			"CampaignData":campaign_data,
			"PlayerData":player_data
			},false,false)
		MusicManager.stop_song(1.0)
		
func load_gig_free_mode() -> void:
	play_ui_sound("ButtonSimple")
	var scene_to_load = await gig_manager.load_active_gig_and_get_scene()
	
	if scene_to_load!=null:
		SceneManager.load_scene(scene_to_load,true,-1,0.0,{"FreePlay":true},false,false)
		MusicManager.stop_song(1.0)
