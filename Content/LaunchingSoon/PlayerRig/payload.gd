extends Node3D
class_name Payload

@export var main_cargo_parts:Array[PackedScene]
@export var top_cargo_scn:PackedScene
@export var cargo_spawn_points:Array[MeshInstance3D]
@export var return_delay:float = 1.0

var cargo_pool:Array[Cargo]

#func _ready() -> void:
##	add a couple extra just in case 
	#var pool_size:int = LaunchSettings.CARGO_TO_FULL + 5
	#setup_cargo_pool(pool_size)
	
func setup_cargo_pool(size:int) -> void:
	for i in range(size):
		var random_idx:int = randi_range(0,main_cargo_parts.size()-1)
		var cargo_instance:Cargo = main_cargo_parts[random_idx].instantiate()
		add_child(cargo_instance)
		cargo_instance.on_reset.connect(return_cargo_to_pool)
		cargo_instance.visible=false
		cargo_pool.append(cargo_instance)
		
func grab_cargo_from_pool() -> Cargo:
	for i in range(cargo_pool.size()):
		if cargo_pool[i]!=null:
			var cargo: Cargo = cargo_pool[i]
			cargo_pool.pop_at(i)
			cargo.visible=true
			return cargo
	return null
	
func return_cargo_to_pool(cargo:Cargo) -> void:
	await get_tree().create_timer(return_delay).timeout
	cargo_pool.append(cargo)
	cargo.reparent(self)
	cargo.visible=false
	cargo.position = Vector3.ZERO
	cargo.rotation = Vector3.ZERO
			
func get_top_cargo() -> Cargo:
	var cargo_instance:Cargo = top_cargo_scn.instantiate()
	add_child(cargo_instance)
	return cargo_instance

func get_next_cargo_scn(structure_size:int) -> PackedScene:
	if structure_size == LaunchSettings.CARGO_TO_FULL-1:
		return top_cargo_scn
	elif structure_size >= 0 and structure_size<LaunchSettings.CARGO_TO_FULL-1:
		var random_idx:int = randi_range(0,main_cargo_parts.size()-1)
		return main_cargo_parts[random_idx]
	else:
		return null
		
func get_random_position_on_surface() -> Vector3:
	# Assuming the MeshInstance3D is assigned to a variable or node reference
	var random_mesh_id:int = randi_range(0,cargo_spawn_points.size()-1)
	var mesh_instance: MeshInstance3D = cargo_spawn_points[random_mesh_id]

	# Get the AABB (Axis-Aligned Bounding Box) of the mesh
	var aabb: AABB = mesh_instance.get_aabb()

	# Transform AABB to global coordinates
	# Translate AABB to global coordinates by adding the MeshInstance3D's global position
	aabb.position += mesh_instance.global_transform.origin

	# Extract dimensions and top surface position
	var min_corner: Vector3 = aabb.position
	var max_corner: Vector3 = aabb.end
	var top_y: float = max_corner.y  # Top surface Y-coordinate in global space

	# Generate random X and Z coordinates within the top surface
	var random_x: float = randf_range(min_corner.x, max_corner.x)
	var random_z: float = randf_range(min_corner.z, max_corner.z)
	
	# Return the random position on the top surface
	return Vector3(random_x, top_y, random_z)
