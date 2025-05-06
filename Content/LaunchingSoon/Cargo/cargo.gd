extends RigidBody3D
class_name Cargo

@export var collider:CollisionShape3D

@export var ray_extra_margin:float = 0.1
@export var stick_strength:float=10
@export var proximity_threshold: float = 0.03 # Distance to snap to target (units)
@export var stick_tween_duration:float = 0.3
@export var max_jump_height:float = 0.2

@export var fall_time_to_kill:float = 3.0

@export var score_label:Label3D

var height:float
var width:float

var velocity_at_collision:Vector3
var time_falling:float=0

var placement_score:int

var place_tier:LaunchSettings.PLACE_TIER

var is_dropping:bool=false
var is_connected:bool=false

#collision detection only available for the first collision shape detected
var has_collided:bool=false
var velocity:Vector3

var collided_cargo:Cargo
var structure:CargoStructure
var structure_stick_point:Vector3

signal on_missed(cargo:Cargo)
signal on_placed(cargo:Cargo)

func _ready() -> void:
	freeze = true
	if collider!=null:
		set_dimensions(collider)
		
# Called when the block is instantiated and released
func release(release_velocity: Vector3):
	# Set initial velocity (e.g., from crane's horizontal movement)
	velocity = release_velocity
	self.global_position.z = 0
	velocity.z = 0
	
	rotation_degrees.x = 0
	rotation_degrees.y = 0
	
	time_falling=0
	is_dropping = true
	
func _process(delta: float) -> void:
	if is_connected:
		return
		
	if !is_dropping:
		if structure!=null:
			var stick_target_dir:Vector3 = structure_stick_point - position
			var distance = stick_target_dir.length()
			if distance<=proximity_threshold:
				self.position = structure_stick_point
				handle_connect()
			else:
				self.position += stick_target_dir*stick_strength*delta
		return
	
	# Apply gravity to velocity
	velocity.y -= LaunchSettings.GRAVITY_STRENGTH * delta
	# Update position based on velocity
	global_position += velocity * delta
	
#	check if shape collision with Cargo.
	var shape_collision:Dictionary = get_shape_collision()
	if !has_collided and shape_collision.size() > 0:
		has_collided = true
		is_dropping=false
		var collided_object = shape_collision["collider"]
		
		if collided_object is Cargo:
			var collision_data:Dictionary = get_collision_data()
			if collision_data.size() > 0:
				process_collision(collision_data)
			else:
				handle_miss(collided_object)
		else:
			print(collided_object.name)
			handle_miss(collided_object)
		
	time_falling += delta
	if time_falling>=fall_time_to_kill:
		print("Load Spent too much time without collision, forcing destroy")
		handle_miss()
	
	
func process_collision(collision_data:Dictionary) -> void:
	collided_cargo = collision_data["collider"] as Cargo
	var hit_pos:Vector3 = collision_data["position"]
	var hit_normal:Vector3 = collision_data["normal"]
	
#	edge case for some reason sometimes structure may be null no clue why
	if collided_cargo.get_parent() == null:
		handle_miss(collided_cargo)
		return
		
	structure = collided_cargo.get_parent() as CargoStructure
	place_tier = structure.get_placement_tier(self,collided_cargo, hit_pos,hit_normal)
	if place_tier == LaunchSettings.PLACE_TIER.NONE:
		handle_miss(collided_cargo)
	else:
		structure.apply_cargo(self)
		var place_point:Vector3
		var place_target_up_dir:Vector3 = collided_cargo.transform.basis.y
		if place_tier == LaunchSettings.PLACE_TIER.LEGEND:
			place_point = collided_cargo.position + place_target_up_dir * height
		else:
			place_point = structure.to_local(hit_pos) + place_target_up_dir * (height / 2.0) # Offset by half height
		place_point.z = collided_cargo.position.z
		structure_stick_point = place_point
		
	
func handle_connect() -> void:
	is_connected=true
	score_label.text = str(LaunchSettings.get_score(place_tier))
	
	await tween_placement()
	on_placed.emit(self)
	
	
func handle_miss(hit_obj=null) -> void:
	if hit_obj == null:
		on_missed.emit(self)
		queue_free()
		return
	
	freeze=false
	
	var hit_direction: Vector3 = (self.global_position - hit_obj.global_position).normalized()
	var normal = hit_direction  # Approximated surface normal
	# Reflect velocity over the normal
	var bounce_direction: Vector3 = velocity - 2.0 * velocity.dot(normal) * normal
	# Apply bounce
	linear_velocity = bounce_direction
	
	# Compute the spin axis (perpendicular to direction change)
	var spin_axis = velocity.normalized().cross(bounce_direction.normalized())
	var spin_angle = velocity.angle_to(bounce_direction)
	var spin_strength = bounce_direction.length() * spin_angle
	angular_velocity += -spin_axis.normalized() * spin_strength * 0.5
	
	if hit_obj.get_parent() != null and hit_obj.get_parent() is CargoStructure:
		hit_obj.get_parent().drop_cargo()
		
	on_missed.emit(self)
	await get_tree().create_timer(1).timeout
	print("DELETING")
	queue_free()
	
func tween_placement() -> void:
	# Calculate the pivot transform (rotate around hitpoint)
	var pivot_offset:Vector3 = transform.inverse() * structure_stick_point# Local hitpoint relative to box center
	
	var start_basis:Basis = transform.basis
	# Get the start and target local up vectors
	var start_up: Vector3 = start_basis.y.normalized()
	var target_up: Vector3 = collided_cargo.transform.basis.y.normalized()

		# Calculate the rotation to align start_up to target_up
	var rotate_axis: Vector3 = start_up.cross(target_up).normalized()
	if rotate_axis.is_zero_approx():
		push_warning("Rotation axis is zero! Up vectors may be parallel or anti-parallel.")
		return
	var end_angle: float = start_up.angle_to(target_up)
#	duration depends on how poorly it was placed
	var accuracy:float = LaunchSettings.get_place_accuracy(place_tier)
	var duration:float = lerpf(stick_tween_duration/5.0,stick_tween_duration,accuracy)
	var jump_height:float = lerpf(max_jump_height/4.0,max_jump_height,accuracy)
		
	var tween = create_tween()
	
	var original_position:Vector3 = self.position
	var jump_position:Vector3 = self.position + self.transform.basis.y.normalized()*0.1
	tween.tween_property(self,"position",jump_position,duration*0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(
		Callable(self, "rotate_around_pivot").bind(pivot_offset, start_basis, rotate_axis,end_angle,is_perfect_placement()),
		0.0, # Start
		1.0, # End
		duration, # Duration (adjust as needed)
	).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
	tween.chain()
	tween.tween_property(self,"position",original_position,duration*0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	
# Method to apply rotation around a pivot point
func rotate_around_pivot(t: float, rotate_offset:Vector3, start_basis:Basis, rotate_axis, end_angle, do_a_flip:bool):
	var current_angle = end_angle * t
	# Create a pivot transform to rotate around the hitpoint
	var current_basis = start_basis.rotated(rotate_axis, current_angle)
	# Apply 360-degree X-axis flip if requested (during return phase)
	if do_a_flip:
		var x_axis = Vector3(1, 0, 0) # Local X-axis
		var flip_angle = 2.0 * PI * t # Full 360 degrees (2π radians)
		current_basis = current_basis.rotated(x_axis, flip_angle)
		
	var pivot_transform = Transform3D.IDENTITY
	pivot_transform = pivot_transform.translated(rotate_offset) # Move to pivot
	pivot_transform.basis = current_basis # Apply rotation
	pivot_transform = pivot_transform.translated(-rotate_offset) # Move back

	# Apply the rotated basis
	transform.basis = pivot_transform.basis
	
func get_shape_collision() -> Dictionary:
	# Perform shape cast
	var space_state = get_world_3d().direct_space_state
	var shape = collider.shape # Use the block's shape (e.g., BoxShape3D)
	var shape_query = PhysicsShapeQueryParameters3D.new()
	shape_query.shape = shape
	shape_query.transform = global_transform # Position shape at block's global position
	# Optionally offset downward to check just below the block
	#shape_query.transform.origin += Vector3(0, -(height / 2.0 + ray_extra_margin), 0)
	
	var cast_distance = height / 2.0 + ray_extra_margin # Distance to cast
	shape_query.motion = velocity.normalized() * cast_distance # Set motion vector
	
	# Exclude this block and the last RigidBody
	shape_query.exclude = [self]
	shape_query.collision_mask = 2 # Check Layer 2
	var result:Array[Dictionary] = space_state.intersect_shape(shape_query, 1) # Max 1 collision
	if result.size()>0:
		return result[0]
	else:
		return {}
	
func get_collision_data() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var origin:Vector3 = self.global_position
	
	var ray_length = height / 2.0 + ray_extra_margin # Ray extends to bottom + margin
	 # Use local negative Y-axis direction transformed to global space
	var direction = -self.global_transform.basis.y
	var end = origin + direction * ray_length # Raycast downward
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self] # Exclude the block itself from raycast
	var result:Dictionary = space_state.intersect_ray(query)
	return result
	
func set_dimensions(collider:CollisionShape3D) -> void:
	if collider.shape is BoxShape3D:
		height = collider.shape.extents.y * 2.0 # Extents are half-size
		width = collider.shape.extents.x * 2.0 # Extents are half-size
	elif collider.shape is CylinderShape3D:
		height = collider.shape.height
		width = collider.shape.radius*2
		
func get_top_point() -> Vector3:
	# Get the local up vector (Y axis in local space)
	var local_up = transform.basis.y.normalized()
	# Calculate the local point offset in the local up direction
	var local_point = local_up * (height / 2.0)
	# Convert to global space
	var global_point = to_global(local_point)
	return global_point
	
func is_perfect_placement() -> bool:
	return place_tier == LaunchSettings.PLACE_TIER.LEGEND
	
func drop_off() -> void:
	self.reparent(get_tree().root)
	freeze = false
	linear_velocity = Vector3(randf_range(-2,2),randf_range(0.4,0.8),randf_range(-2,2))
	print(linear_velocity)
	await get_tree().create_timer(1).timeout
	queue_free()
