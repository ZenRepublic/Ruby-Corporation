extends RigidBody3D
class_name Cargo

@export var collider:CollisionShape3D
@export var mesh:MeshInstance3D

@export var ray_extra_margin:float = 0.1

@export var stick_strength:float=10
@export var proximity_threshold: float = 0.03 # Distance to snap to target (units)

@export var fall_time_to_kill:float = 3.0

@export var score_label:Label3D

var height:float
var width:float

var stick_pos:Vector3 = Vector3.ZERO
var velocity_at_collision:Vector3
var time_falling:float=0

var ROTATION_CORRECTION_SPEED:float = 10

var placement_score:int

signal on_expired()
signal on_placed(cargo:Cargo)

func _ready() -> void:
	freeze = true
	# Calculate block height from collider
	if collider!=null and collider.shape is BoxShape3D:
		height = collider.shape.extents.y * 2.0 # Extents are half-size
		width = collider.shape.extents.x * 2.0 # Extents are half-size
		
# Called when the block is instantiated and released
func release(initial_velocity: Vector3):
	freeze = false
	# Set initial velocity (e.g., from crane's horizontal movement)
	linear_velocity = initial_velocity
	time_falling=0
	
func _process(delta: float) -> void:
	if freeze:
		if stick_pos!= Vector3.ZERO:
			var stick_target_dir:Vector3 = stick_pos - global_position
			var distance = stick_target_dir.length()
			if distance<=proximity_threshold:
				self.global_position = stick_pos
				stick_pos=Vector3.ZERO
			else:
				self.global_position += stick_target_dir*stick_strength*delta
		return
		
	# Perform raycast downward
	var space_state = get_world_3d().direct_space_state
	var origin:Vector3 = self.global_position
	var ray_length = height / 2.0 + ray_extra_margin # Ray extends to bottom + margin
	var end = origin + Vector3(0, -ray_length, 0) # Raycast downward
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self] # Exclude the block itself from raycast
	var result = space_state.intersect_ray(query)

	if result:
		handle_collision(result.collider, result.position, result.normal)
		
	time_falling += delta
	if time_falling>=fall_time_to_kill:
		print("Load Spent too much time without collision, forcing destroy")
		destroy()
	
	
func handle_collision(collided_object, hit_pos:Vector3, hit_normal:Vector3) -> void:
	if collided_object is DeathZone:
		print("DEATH ZONE")
		destroy()
		return
		
	if collided_object is Cargo:
		var structure:CargoStructure = collided_object.get_parent() as CargoStructure
		structure.handle_collision_with_cargo(self, collided_object, hit_pos, hit_normal)
	elif collided_object is Launchpad:
		var structure:CargoStructure = collided_object.cargo_structure
		print(structure.is_started())
		if !structure.is_started():
			stick_on_structure(hit_pos + Vector3(0, height / 2.0, 0))
			structure.apply_cargo(self)
	
func stick_on_structure(stick_pos:Vector3, is_perfect_connect:bool=false) -> void:
	self.stick_pos = stick_pos
	
	freeze = true
	velocity_at_collision = linear_velocity
	linear_velocity = Vector3.ZERO # Stop movement
	
	on_placed.emit(self)
	pass
	
func set_placement_score(score:int) -> void:
	placement_score = score
	score_label.text = str(placement_score)

func correct_rotation(anchor_point: Vector3, collider: Node, normal: Vector3) -> void:
	# Correct the block's rotation to align with the collided block
	# Assume the collided block's up direction is along Y-axis (adjust if needed)
	var target_up: Vector3 = Vector3.UP  # Desired up direction
	var current_up: Vector3 = global_transform.basis.y.normalized()  # Current up direction

	# Calculate the rotation needed to align the block
	var rotation_axis: Vector3 = current_up.cross(target_up).normalized()
	var rotation_angle: float = acos(current_up.dot(target_up))

	if rotation_axis.length_squared() > 0 and not is_nan(rotation_angle):
		# Apply smooth rotation correction
		var target_rotation: Basis = Basis.IDENTITY.rotated(rotation_axis, rotation_angle)
		global_transform.basis = global_transform.basis.slerp(target_rotation, ROTATION_CORRECTION_SPEED * get_process_delta_time())

	# Optionally, adjust position to pivot around the anchor point
	# This ensures the block rotates around the collision point
	var offset: Vector3 = global_position - anchor_point
	global_position = anchor_point + offset.rotated(rotation_axis, rotation_angle)
	
	
func get_top_point() -> Vector3:
	return self.global_position + Vector3(0,height/2,0)
	
func destroy() -> void:
	on_expired.emit()
	queue_free()
	
