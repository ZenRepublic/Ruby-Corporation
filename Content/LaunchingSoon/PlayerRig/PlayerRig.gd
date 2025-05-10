extends Node3D
class_name PlayerRig

@export var cam:CamController
@export var drone:CarrierDrone
@export var payload:Payload
@export var launchpad:Launchpad

@export var token_spawner:TokenSpawner
@export var token_texture:Texture2D

@export var fly_duration:float=0.6

@export var offset_from_launchpad:Vector3

var curr_value:float=0.0
var curr_warnings:int = 0

var launch_controller:LaunchController
var original_pos:Vector3=Vector3.ZERO

var gui:GUI

signal on_rise_complete()
signal on_value_updated(new_value:float)
signal on_warning_received(warning_amount:int)

func _ready() -> void:
	gui = get_tree().get_first_node_in_group("GUI") as GUI
	
	on_rise_complete.connect(set_original_pos,CONNECT_ONE_SHOT)
	
	drone.global_position = payload.get_random_position_on_surface()
	drone.on_dropped.connect(return_drone)
	
	launchpad.cargo_structure.on_cargo_dropped.connect(apply_destruction_penalty)
	
	launch_controller = get_tree().get_first_node_in_group("LaunchController") as LaunchController
	launch_controller.setup_complete.connect(setup_rig)
	
func setup_rig() -> void:
	token_spawner.setup_token_pool(ClubhouseProgram.claimer.get_reward_token_texture())
	token_spawner.on_toked_arrived.connect(update_launch_value)
	
	prepare_cargo_drop()
	
func set_original_pos() -> void:
	original_pos = self.global_position
	
func _process(delta: float) -> void:
	# Drop block on input
	if Input.is_action_just_pressed("ui_accept"): # Spacebar
		drone.try_drop_load()
		
func prepare_cargo_drop() -> void:
	drone.update_difficulty(launchpad.get_structure_size())
	send_cargo(launchpad.get_drop_point())
	
	var target_pos:Vector3 = self.global_position
	target_pos.y = launchpad.get_rig_fly_point().y
	target_pos += offset_from_launchpad
	
	move_to(target_pos,fly_duration)
		
func send_cargo(deploy_point:Vector3) -> void:
	var cargo_scn:PackedScene = payload.get_next_cargo_scn(launchpad.get_structure_size())
	var cargo_instance:Cargo = cargo_scn.instantiate()
	if !drone.is_at_destination:
		await drone.on_target_reached
	drone.grab_cargo(cargo_instance)
	drone.fly_to(deploy_point, cam.global_position)
	
func return_drone(dropped_cargo:Cargo) -> void:
	dropped_cargo.on_missed.connect(process_failed_drop,CONNECT_ONE_SHOT)
	dropped_cargo.on_placed.connect(process_successful_drop,CONNECT_ONE_SHOT)
	if !drone.is_at_destination:
		await drone.on_target_reached
	drone.fly_to(payload.get_random_position_on_surface())
	
func descend_to_base() -> void:
	if token_spawner.is_sending:
		await token_spawner.on_send_finished
	await move_to(original_pos,3.0)
	cam.set_look_target(launchpad.cargo_structure.cargo_base)

func move_to(fly_point:Vector3, duration:float) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)  # Smooth easing
	tween.set_ease(Tween.EASE_IN_OUT)

	# Tween the position over 1 second
	tween.tween_property(self, "global_position", fly_point, duration)
	await tween.finished
	on_rise_complete.emit()
	
func process_successful_drop(cargo:Cargo) -> void:
	cam.knock_back(cargo.global_position,LaunchSettings.get_place_accuracy(cargo.place_tier))
	
	var tokens_earned:float = LaunchSettings.get_score(cargo.place_tier)
	token_spawner.send_tokens(tokens_earned,cargo)
	
	launch_controller.narrator.play_encourgement(cargo.place_tier)
	gui.do_placement_effect(cargo.place_tier)
	
	launchpad.handle_structure_update()
	
	if !launchpad.is_structure_complete():
		prepare_cargo_drop()
	else:
		drone.visible=false
		
	if cargo.animator!=null:
		await get_tree().create_timer(token_spawner.send_duration).timeout
		cargo.animator.play("depositing")
		await token_spawner.on_send_finished
		cargo.animator.play("close")
		
func update_launch_value(change_amount:float) -> void:
	curr_value += change_amount
	if curr_value<0:
		curr_value = 0
	
	on_value_updated.emit(curr_value)

func process_failed_drop(cargo:Cargo) -> void:
	update_launch_value(-LaunchSettings.PENALTY_VALUE)
	
	cam.start_shake(0.6,0.08)
	curr_warnings += 1
	on_warning_received.emit(curr_warnings)

	launchpad.handle_structure_update()
	
	if curr_warnings < LaunchSettings.WARNINGS_TO_FIRE:
		prepare_cargo_drop()
		
func apply_destruction_penalty(dropped_cargo:Cargo) -> void:
	var token_value:float = LaunchSettings.get_score(dropped_cargo.place_tier)
	var base_penalty:float = LaunchSettings.PENALTY_VALUE
	var final_penalty:float = base_penalty + token_value
	update_launch_value(-final_penalty)
