extends RigidBody3D
class_name Cargo

@export var collider:CollisionShape3D

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

var is_dropping:bool=false

#collision detection only available for the first collision shape detected
var has_collided:bool=false
var velocity:Vector3

signal on_expired()
signal on_connected()

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
	if !is_dropping:
		if stick_pos!= Vector3.ZERO:
			var stick_target_dir:Vector3 = stick_pos - global_position
			var distance = stick_target_dir.length()
			if distance<=proximity_threshold:
				self.global_position = stick_pos
				stick_pos=Vector3.ZERO
				on_connected.emit()
			else:
				self.global_position += stick_target_dir*stick_strength*delta
		return
	
	# Apply gravity to velocity
	velocity.y -= LaunchSettings.GRAVITY_STRENGTH * delta
	# Update position based on velocity
	global_position += velocity * delta
	
#	check if shape collision with Cargo.
	var shape_collision:Dictionary = get_shape_collision()
	if !has_collided and shape_collision.size() > 0:
		has_collided = true
		var collided_object = shape_collision["collider"]
		
		if collided_object is Cargo or collided_object is Launchpad:
			var collision_data:Dictionary = get_collision_data()
			if collision_data.size() > 0:
				process_collision(collision_data)
			else:
				handle_miss(collided_object)
		else:
			handle_miss(collided_object)
		
	time_falling += delta
	if time_falling>=fall_time_to_kill:
		print("Load Spent too much time without collision, forcing destroy")
		handle_miss()
	
	
func process_collision(collision_data:Dictionary) -> void:
	is_dropping=false	
	var collided_object = collision_data["collider"]
	var hit_pos:Vector3 = collision_data["position"]
	var hit_normal:Vector3 = collision_data["normal"]
	
	if collided_object is Cargo:
		var structure:CargoStructure = collided_object.get_parent() as CargoStructure
		placement_score = structure.get_placement_score(self,collided_object, hit_pos,hit_normal)
		if placement_score == 0:
			handle_miss(collided_object)
		else:
			handle_connect(collided_object,hit_pos)
			structure.apply_cargo(self,placement_score)
	else:
		handle_miss(collided_object)
		
	
func handle_connect(collided_object, hit_point:Vector3) -> void:
	if placement_score == LaunchSettings.get_max_placement_score():
		stick_pos = collided_object.global_position + Vector3(0,height,0)
	else:
		stick_pos = hit_point + Vector3(0, height / 2.0, 0) # Offset by half height
		
	stick_pos.z = collided_object.global_position.z
	score_label.text = str(placement_score)
	pass
	
	
func handle_miss(hit_obj=null) -> void:
	if hit_obj == null:
		on_expired.emit()
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
	
	on_expired.emit()
	await get_tree().create_timer(1).timeout
	queue_free()


func handle_physics_collision(body: Node3D) -> void:
	linear_velocity = velocity
	freeze=false
	pass # Replace with function body.
	
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
	var end = origin + Vector3(0, -ray_length, 0) # Raycast downward
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
