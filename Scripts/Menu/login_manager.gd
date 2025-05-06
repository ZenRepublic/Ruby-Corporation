extends Node
class_name LoginManager

@export_file(".tscn") var scene_path:String
@export_file(".tscn") var game_scene_path:String
#@onready var animation_player:AnimationPlayer = $AnimationPlayer
#@onready var secret_code_input:SecretCodeInput = $SecretCodeInput

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicManager.play_song("Login")
	SolanaService.wallet.on_login_success.connect(handle_login)

func _on_connect_button_pressed() -> void:
	#if generated wallet option, it will just login, if not, it will trigger on_login_begin
	MusicManager.play_sound("ButtonJuicy")
	initiate_login("")
	
func initiate_login(_finished_anim:String) -> void:
	SolanaService.wallet.try_login()
	
func handle_login() -> void:
	SceneManager.load_scene(scene_path,false)

func launch_game_secret(_code_entered:String)-> void:
	load_free_play_game()

func load_free_play_game() -> void:
	SceneManager.load_scene(game_scene_path,true,-1,0.0,{"FreePlay":true})
