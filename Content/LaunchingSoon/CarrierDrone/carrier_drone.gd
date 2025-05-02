extends Node3D
class_name CarrierDrone

@export var base_speed:float = 80
@export var speed_growth_tick:float = 10
@export var speed_multiplier_curve:Curve

@export var start_move_range:Vector3 = Vector3(0.15,0.02,0.0)
@export var max_move_range:Vector3 = Vector3(0.4,0.3,0.0)
@export var amplitude_growth_tick = Vector3(0.01,0.02,0.0)

@export var spawn_point:Node3D

var curr_speed:float
var curr_move_range:Vector3

var curr_cargo:Cargo

var velocity:Vector3 = Vector3.ZERO
var prev_pos:Vector3

#used for oscillation
var time_elapsed:float=0

var target_point:Vector3

var is_at_destination:bool

signal on_dropped(cargo:Cargo)

func _ready() -> void:
	prev_pos = self.global_position
	curr_speed = base_speed
	curr_move_range = start_move_range
	

func _process(delta):
	var target_pos:Vector3 = target_point
	var speed:float = curr_speed
	
	# Calculate oscillation (ranges from -1 to 1) when ready to drop cargo
	if is_at_destination:
		if curr_cargo!=null:
			var oscillation: Vector3
			oscillation.x = sin(time_elapsed * curr_speed)
			oscillation.y = sin(time_elapsed * curr_speed) * cos(time_elapsed * curr_speed)
			
			var x_position:float = (self.global_position.x - target_point.x) / curr_move_range.x  # Normalize x-position to [-1, 1]
			x_position = clamp(x_position, -1.0, 1.0)  # Ensure it stays in range
		#   oscilates from -1 to 1 to guide drone
			target_pos.x += oscillation.x * curr_move_range.x # Apply scaled oscillation
			target_pos.y += oscillation.y * curr_move_range.y
			
			speed *= speed_multiplier_curve.sample(x_position)
			time_elapsed+=delta
	else:
		speed *= 2.0
		
	var dir_to_target:Vector3 = (target_pos - self.global_position)
	var distance_to_target: float = dir_to_target.length()
	
	#print(distance_to_target)
	#if distance_to_target > 0.0:  # Avoid division by zero
	# Scale movement speed based on distance to target for smooth approach
	var new_position:Vector3 = self.global_position.move_toward(target_pos, speed * delta)
	global_position = new_position
	#var smooth_factor:float = clamp(distance_to_target * speed, 0, speed)  # Proportional speed
	#var move_delta:Vector3 = dir_to_target.normalized() * smooth_factor * delta
	#self.global_position += move_delta  # Move smoothly toward target
	
	if !is_at_destination and distance_to_target < 0.02:
		self.global_position = target_pos
		is_at_destination=true
		time_elapsed=0
	
	velocity = (self.global_position-prev_pos) / delta
	
	# Store current position for next frame
	prev_pos = self.global_position
		
		
func try_drop_load() -> void:
	if curr_cargo == null or !is_at_destination:
		return
	
	curr_cargo.reparent(get_tree().root)
	
	#var load_velocity:Vector3 = velocity
	#load_velocity.x /= curr_cargo.mass #make the velocity be affected by mass
	#load_velocity.y = 0
	
	curr_cargo.release(velocity)
	
	on_dropped.emit(curr_cargo)
	curr_cargo = null
	
func grab_cargo(cargo:Cargo, increase_difficulty:bool=false) -> void:
	if increase_difficulty:
		curr_speed += speed_growth_tick
		curr_move_range += amplitude_growth_tick
		curr_move_range = curr_move_range.clamp(start_move_range,max_move_range)
		
	#print(curr_speed)
	#print(curr_move_range)
	
	attach_cargo(cargo)
	self.visible = true
	
	
func attach_cargo(cargo:Cargo) -> void:
	spawn_point.add_child(cargo)
	cargo.position += Vector3(0,0,-cargo.height/2)
	curr_cargo = cargo
	
func fly_to(position:Vector3) -> void:
	target_point = position
	is_at_destination=false
