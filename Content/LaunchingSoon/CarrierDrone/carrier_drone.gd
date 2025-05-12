extends Node3D
class_name CarrierDrone

@onready var line_renderer = $LineRenderer3D

@export var magnet_puck:MagnetPuck

@export var base_speed:float = 2
@export var max_speed:float = 5
@export var speed_growth_tick:float = 0.05
@export var speed_multiplier_curve:Curve

@export var start_move_range:Vector3 = Vector3(0.15,0.02,0.0)
@export var max_move_range:Vector3 = Vector3(0.4,0.3,0.0)

@export var audio_source:AudioStreamPlayer3D
@export var pitch_range:Vector2
var amplitude_growth_tick:Vector3

var curr_speed:float
var curr_move_range:Vector3
var curr_cargo:Cargo

#var velocity:Vector3 = Vector3.ZERO
var prev_pos:Vector3
#used for oscillation
var oscillation_time:float=0

var target_point:Vector3
var is_at_destination:bool=true

var look_target:Vector3
var tilt_strength:float = 5.0
var max_tilt = deg_to_rad(90) # Max tilt in degrees
var tilt_influence = 0.5 # 0 = ignore tilt, 1 = full tilt affects look

var speed:float

signal on_dropped(cargo:Cargo)
signal on_target_reached()

func _ready() -> void:
	prev_pos = self.global_position	
	curr_speed = base_speed
	curr_move_range = start_move_range
	speed = curr_speed
	
	amplitude_growth_tick = (max_move_range-start_move_range)/(LaunchSettings.CARGO_TO_FULL/2)
	
	line_renderer = $LineRenderer3D
	

func _process(delta):
	line_renderer.points[0] = self.global_position
	line_renderer.points[1] = magnet_puck.global_position
	
	if target_point == Vector3.ZERO:
		return
		
	audio_source.pitch_scale = lerpf(pitch_range.x,pitch_range.y,speed/max_speed)
	
	if !is_at_destination:
		if speed < curr_speed * 2.0:
			speed *= 1.1
		else:
			speed = curr_speed * 2.0
	else:
		if speed > curr_speed:
			speed *= 0.95
		else:
			speed = curr_speed
			
	
	var target_pos:Vector3 = target_point if !is_at_destination else apply_oscillation(target_point)
	if is_at_destination and curr_cargo != null:
		oscillation_time += delta
		
	var dir_to_target:Vector3 = (target_pos - self.global_position)
	var distance_to_target: float = dir_to_target.length()
	
	var new_position:Vector3 = self.global_position.move_toward(target_pos, speed * delta)
	prev_pos = global_position
	global_position = new_position
	
	
	if look_target!=Vector3.ZERO:
		look_at_target(look_target, 50 * delta)
	
	if !is_at_destination and distance_to_target < 0.03:
		self.global_position = target_pos
		is_at_destination=true
		on_target_reached.emit()
	
func fly_to(position:Vector3, look_target:Vector3 = Vector3.ZERO) -> void:
	target_point = position
	if look_target == Vector3.ZERO:
		look_target = target_point
	else:
		self.look_target = look_target
	is_at_destination=false
	
func grab_cargo(cargo:Cargo) -> void:		
	cargo.reparent(magnet_puck.spawn_point)
	cargo.position = Vector3(0,-cargo.height/2,0)
	cargo.rotation = Vector3.ZERO
	curr_cargo = cargo
	self.visible = true

func try_drop_load() -> void:
	if curr_cargo == null or !is_at_destination:
		return
	
	curr_cargo.reparent(get_tree().root)
	curr_cargo.release(magnet_puck.velocity)
	on_dropped.emit(curr_cargo)
	curr_cargo = null
	
func update_difficulty(structure_size:int) -> void:
	curr_speed = base_speed + speed_growth_tick*structure_size
	curr_move_range = start_move_range + amplitude_growth_tick*structure_size
	curr_move_range = curr_move_range.clamp(start_move_range,max_move_range)
	
func apply_oscillation(target_position:Vector3) -> Vector3:
	var osc_x = sin(oscillation_time * curr_speed)
	var osc_y = sin(oscillation_time * curr_speed) * cos(oscillation_time * curr_speed)

	target_position.x += osc_x * curr_move_range.x
	target_position.y += osc_y * curr_move_range.y
	return target_position
	
	## make the movement speed irregular based on oscillation	
	#var x_position:float = (self.global_position.x - target_point.x) / curr_move_range.x  # Normalize x-position to [-1, 1]
	#x_position = clamp(x_position, -1.0, 1.0)  # Ensure it stays in range
	#speed *= speed_multiplier_curve.sample(x_position)
	#return target_position
	
func look_at_target(target:Vector3, rotation_speed:float) -> void:
	var forward_dir:Vector3 = (target - global_position).normalized()
	var look_basis = Basis().looking_at(-forward_dir, Vector3.UP)
	var look_quat = Quaternion(look_basis)
	
	
	var tilt_quat = Quaternion.IDENTITY	
	
	var velocity:Vector3 = get_velocity()
	if velocity.length() > 0.01:
		# Work in the local space of the look direction
		var right = look_basis.x.normalized()
		var up = look_basis.y.normalized()

		# Dot velocity with local right and up for tilt influence
		var roll_amount = clamp(velocity.dot(right) * tilt_strength, -1.0, 1.0) * max_tilt  # X axis tilt (side)
		var pitch_amount = clamp(velocity.dot(up) * tilt_strength, -1.0, 1.0) * max_tilt    # Y axis tilt (up/down)

		var roll_quat = Quaternion(right, roll_amount)
		var pitch_quat = Quaternion(up, -pitch_amount)

		# Combine tilts (order matters slightly)
		tilt_quat = pitch_quat * roll_quat
		
	var look_with_tilt = look_quat * tilt_quat
	var target_quat = look_quat.slerp(look_with_tilt, tilt_influence)
			
	var current_quat = global_transform.basis.get_rotation_quaternion()
	var new_quat = current_quat.slerp(target_quat, rotation_speed)
	global_transform.basis = Basis(new_quat)
	
func get_velocity() -> Vector3:
	return prev_pos - self.global_position
