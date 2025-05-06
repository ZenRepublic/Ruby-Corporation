extends Node
class_name LaunchController

@export var launchpad:Launchpad
@export var player_rig:PlayerRig
@export var gui:GUI
@export var narrator:Narrator

var free_play_mode:bool

signal setup_complete()
signal on_salary_updated(new_salary:float)

func _init() -> void:
	add_to_group("LaunchController")

func _ready() -> void:
	player_rig.on_warning_received.connect(process_warning)
	launchpad.on_structure_complete.connect(send_off)
	
	free_play_mode = SceneManager.get_interscene_data("FreePlay")
	if !free_play_mode:
		await setup_reward_claimer()
	await launchpad.activate()
	setup_complete.emit()
	

func process_warning(warnings_received:int) -> void:
	if warnings_received < LaunchSettings.WARNINGS_TO_FIRE:
		return
	fire_builder()
	
	
func fire_builder() -> void:
# 	handle loss
	print("GAME LOST")
	narrator.say("Lose")
	gui.handle_lose_ui()
	pass
	
func send_off() -> void:
#	handle win
	await player_rig.descend_to_base()
	await launchpad.launch_structure()
	print("GAME WIN")
	narrator.say("Win")
	gui.handle_win_ui()
	pass
	
func setup_reward_claimer() -> void:
	var campaign_key = SceneManager.get_interscene_data("CampaignKey")
	var campaign_data = SceneManager.get_interscene_data("CampaignData")
	var player_data = SceneManager.get_interscene_data("PlayerData")
	
	if campaign_key == null or campaign_data == null or player_data == null:
		push_error("Failed to get clubhouse data from scene manager")
		return
	
	await ClubhouseProgram.claimer.setup_claimer(campaign_key,campaign_data,player_data)
	
func convert_to_tokens(score:float) -> float:
	if free_play_mode:
		return score
		
	return ClubhouseProgram.claimer.get_token_value(score)

func get_reward_token_visual() -> Texture2D:
	if free_play_mode:
		return null
	
	return ClubhouseProgram.claimer.get_reward_token_texture()
	
	
