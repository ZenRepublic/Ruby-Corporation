extends Node
class_name LaunchController

@export var structure:CargoStructure
@export var launchpad:Launchpad
@export var rig:SkyRig
@export var token_spawner:TokenSpawner
@export var gui:GUI

@export var token_texture:Texture2D

var curr_value:float=0.0
var curr_warnings:int = 0

signal on_floor_changed(curr_floor:int)
signal on_salary_updated(new_salary:float)
signal on_warning_received(warning_amount:int)

func _init() -> void:
	add_to_group("LaunchController")

func _ready() -> void:
	await launchpad.activate()
	prepare_drop()
	structure.on_cargo_placed.connect(process_cargo_placed)
	token_spawner.setup_token_pool(get_token_visual())
	token_spawner.on_toked_arrived.connect(update_salary)
	pass
	
func get_token_visual() -> Image:
	return token_texture.get_image()
	
func process_cargo_placed(cargo:Cargo, placement_score:int) -> void:
	var tokens_earned:float = get_salary(placement_score)
	token_spawner.send_tokens(tokens_earned,cargo.get_top_point())
	
	on_floor_changed.emit(structure.get_size())
	
	if structure.is_complete():
		send_off()
	else:
		prepare_drop()
	
func process_cargo_destroyed() -> void:
	curr_warnings += 1
	on_warning_received.emit(curr_warnings)
	
	if curr_warnings == LaunchSettings.WARNINGS_TO_FIRE:
		fire_builder()
	else:
		prepare_drop()
		
func prepare_drop() -> void:
	rig.send_cargo(launchpad.get_drop_point())
	
	var rig_fly_point:Vector3 = (launchpad.get_drop_point() + structure.get_highest_point())/2
	
	rig.fly_towards(rig_fly_point)
	
func update_salary(change_amount:float) -> void:
	curr_value += change_amount
	on_salary_updated.emit(curr_value)
	
func get_salary(score:int) -> float:
#	add score conversion to token
	return float(score)
	
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
	
