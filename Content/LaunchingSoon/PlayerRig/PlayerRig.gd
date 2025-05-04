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

var gui:GUI

signal on_rise_complete()
signal on_warning_received(warning_amount:int)

func _ready() -> void:
	gui = get_tree().get_first_node_in_group("GUI") as GUI
	
	drone.global_position = payload.get_random_position_on_surface()
	drone.on_dropped.connect(return_drone)
	
	token_spawner.setup_token_pool(token_texture.get_image())
	token_spawner.on_toked_arrived.connect(update_launch_value)
	
	launchpad.on_setup_complete.connect(prepare_cargo_drop)
	
func _process(delta: float) -> void:
	# Drop block on input
	if Input.is_action_just_pressed("ui_accept"): # Spacebar
		drone.try_drop_load()
		
func prepare_cargo_drop() -> void:
	drone.update_difficulty(launchpad.get_structure_size())
	send_cargo(launchpad.get_drop_point())
	move_to(launchpad.get_rig_fly_point())
		
func send_cargo(deploy_point:Vector3) -> void:
	var cargo_scn:PackedScene = payload.get_next_cargo_scn(launchpad.get_structure_size())
	var cargo_instance:Cargo = cargo_scn.instantiate()
	if !drone.is_at_destination:
		await drone.on_target_reached
	drone.grab_cargo(cargo_instance)
	drone.fly_to(deploy_point, cam.global_position)
	
func return_drone(dropped_cargo:Cargo) -> void:
	dropped_cargo.on_missed.connect(process_failed_drop)
	dropped_cargo.on_placed.connect(process_successful_drop)
	if !drone.is_at_destination:
		await drone.on_target_reached
	drone.fly_to(payload.get_random_position_on_surface())

func move_to(fly_point:Vector3) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)  # Smooth easing
	tween.set_ease(Tween.EASE_IN_OUT)

	# Calculate target position
	var target_pos:Vector3 = self.global_position
	target_pos.y = fly_point.y
	target_pos += offset_from_launchpad

	# Tween the position over 1 second
	tween.tween_property(self, "position", target_pos, fly_duration)
	await tween.finished
	on_rise_complete.emit()
	
func process_successful_drop(cargo:Cargo,placement_score:int) -> void:
	var tokens_earned:float = float(placement_score)
	token_spawner.send_tokens(tokens_earned,cargo.get_top_point())
	
	if !launchpad.is_structure_complete():
		prepare_cargo_drop()
	pass
		
func update_launch_value(change_amount:float) -> void:
	curr_value += change_amount
	gui.admin_panel.update_launchpad_value_display(curr_value)

func process_failed_drop() -> void:
	cam.start_shake(0.3,0.05)
	curr_warnings += 1
	on_warning_received.emit(curr_warnings)
	gui.admin_panel.update_warnings_display(curr_warnings)
	
	if curr_warnings < LaunchSettings.WARNINGS_TO_FIRE:
		prepare_cargo_drop()
	
