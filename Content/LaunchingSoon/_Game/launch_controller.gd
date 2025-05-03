extends Node
class_name LaunchController

@export var launchpad:Launchpad
@export var player_rig:PlayerRig
@export var gui:GUI

signal on_salary_updated(new_salary:float)

func _init() -> void:
	add_to_group("LaunchController")

func _ready() -> void:
	player_rig.on_warning_received.connect(process_warning)
	launchpad.on_structure_complete.connect(send_off)
	
	await launchpad.activate()
	

func process_warning(warnings_received:int) -> void:
	if warnings_received < LaunchSettings.WARNINGS_TO_FIRE:
		return
	fire_builder()
	
	
func fire_builder() -> void:
# 	handle loss
	print("GAME LOST")
	gui.handle_lose_ui()
	pass
	
func send_off() -> void:
#	handle win
	print("GAME WIN")
	gui.handle_win_ui()
	pass
	
