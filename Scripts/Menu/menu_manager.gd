extends Node
class_name MenuManager

@export var screen_manager:ScreenManager

@export_file(".tscn") var game_scene_path:String
@export var campaign_interactor:CampaignInteractor

# Called when the node enters the scene tree for the first time.

func _init() -> void:
	add_to_group("MenuManager")
	
func _ready() -> void:
	MusicManager.play_song("Menu")
	campaign_interactor.on_game_started.connect(load_game)

func play_ui_sound(sound_name:String) -> void:
	MusicManager.play_sound(sound_name)
	
	
func load_game(campaign_key:Pubkey,campaign_data:Dictionary,player_data:Dictionary) -> void:
	MusicManager.play_sound("ButtonSimple")
	SceneManager.load_scene(game_scene_path,true,-1,0.2,{
		"GameMode":GameManager.GameMode.MINING,
		"CampaignKey":campaign_key,
		"CampaignData":campaign_data,
		"PlayerData":player_data
		})
