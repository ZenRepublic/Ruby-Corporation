extends Node3D
class_name SkyRig

@export var cam:CamController
@export var drone:CarrierDrone
@export var payload:Payload

@export var fly_duration:float=0.6

@export var offset_from_launchpad:Vector3
var launch_controller:LaunchController

signal on_rise_complete()

func _ready() -> void:
	launch_controller = get_tree().get_first_node_in_group("LaunchController") as LaunchController
	drone.global_position = payload.get_random_position_on_surface()
	drone.on_dropped.connect(return_drone)
	
func _process(delta: float) -> void:
	# Drop block on input
	if Input.is_action_just_pressed("ui_accept"): # Spacebar
		drone.try_drop_load()
		
		
func send_cargo(deploy_point:Vector3) -> void:
	var cargo_scn:PackedScene = payload.get_next_cargo_scn(launch_controller.structure)
	var cargo_instance:Cargo = cargo_scn.instantiate()
	if !drone.is_at_destination:
		await drone.on_target_reached
	drone.grab_cargo(cargo_instance,false)
	drone.fly_to(deploy_point, cam.global_position)
	
func return_drone(dropped_cargo:Cargo) -> void:
	dropped_cargo.on_expired.connect(process_failed_drop)
	if !drone.is_at_destination:
		await drone.on_target_reached
	drone.fly_to(payload.get_random_position_on_surface())

func fly_towards(fly_point:Vector3) -> void:
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


func process_failed_drop() -> void:
	cam.start_shake(0.3,0.05)
	launch_controller.process_cargo_destroyed()
	
