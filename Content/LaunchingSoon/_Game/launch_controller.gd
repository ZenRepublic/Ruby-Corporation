extends Node
class_name LaunchController

@export var menu_scn_path:String
@export var launchpad:Launchpad
@export var player_rig:PlayerRig
@export var gui:GUI
@export var narrator:Narrator

@export var reward_claimer:CampaignRewardClaimer

var free_play_mode:bool

signal setup_complete()
signal on_salary_updated(new_salary:float)

func _init() -> void:
	add_to_group("LaunchController")

func _ready() -> void:
	player_rig.on_warning_received.connect(process_warning)
	player_rig.on_value_updated.connect(display_score)
	launchpad.on_structure_complete.connect(send_off)
	
	free_play_mode = SceneManager.get_interscene_data("FreePlay")
	if !free_play_mode:
		await setup_reward_claimer()
		
	await launchpad.activate()

	gui.do_effect("Start")
	await get_tree().create_timer(1.5).timeout
	MusicManager.play_song("Game",true,1)
	setup_complete.emit()
	

func process_warning(warnings_received:int) -> void:
	gui.admin_panel.update_warnings_display(warnings_received)
	
	if warnings_received >= LaunchSettings.WARNINGS_TO_FIRE:
		fire_builder()
	else:
		await get_tree().create_timer(0.2).timeout
		gui.do_effect("Warning")
		await get_tree().create_timer(0.3).timeout
		narrator.play_groan()
	
func display_score(new_score:float) -> void:
	var token_value:float =snappedf(convert_to_tokens(new_score),0.01)
	gui.admin_panel.update_launchpad_value_display(token_value)
	
	
func fire_builder() -> void:
# 	handle loss
	print("GAME LOST")
	await MusicManager.stop_song(0.3)
	gui.do_effect("Fired")
	await get_tree().create_timer(2.5).timeout
	
	var severance_amount:float = convert_to_tokens(LaunchSettings.get_lose_score())
	gui.handle_lose_ui(severance_amount)
	MusicManager.play_song("Lose",true,0.5)
	pass
	
func send_off() -> void:
#	handle win
	gui.hide_admin_panel()
	MusicManager.play_song("Win",true,0.5)
	MusicManager.on_song_ended.connect(play_win_loop,CONNECT_ONE_SHOT)
	await player_rig.descend_to_base()
	
	gui.do_effect("GoodLuck")
	await launchpad.launch_structure()
	
	var earn_amount:float = convert_to_tokens(player_rig.curr_value)
	gui.handle_win_ui(earn_amount)
	print("GAME WIN")
	pass

func play_win_loop() -> void:
	MusicManager.play_song("WinLoop",false)
	
	
func setup_reward_claimer() -> void:
	var campaign_key = SceneManager.get_interscene_data("CampaignKey")
	var campaign_data = SceneManager.get_interscene_data("CampaignData")
	var player_data = SceneManager.get_interscene_data("PlayerData")
	
	if campaign_key == null or campaign_data == null or player_data == null:
		push_error("Failed to get clubhouse data from scene manager")
		return
	
	await ClubhouseProgram.claimer.setup_claimer(campaign_key,campaign_data,player_data,LaunchSettings.get_max_score())
	
func convert_to_tokens(score:float) -> float:
	if free_play_mode:
		return score
		
	return ClubhouseProgram.claimer.get_token_value(score,false)

func get_reward_token_visual() -> Texture2D:
	if free_play_mode:
		return null
	
	return ClubhouseProgram.claimer.get_reward_token_texture()
	
func restart_game() -> void:
	SceneManager.reload_scene(true,-1,{
		"FreePlay":false,
		"CampaignKey":ClubhouseProgram.claimer.campaign_key,
		"CampaignData":ClubhouseProgram.claimer.campaign_data,
		"PlayerData":ClubhouseProgram.claimer.player_data
	})
	
func return_to_menu() -> void:
	SceneManager.load_scene(menu_scn_path,true,-1,0.2)
	
	
