extends Node3D
class_name Payload

@export var main_cargo_parts:Array[PackedScene]
@export var top_cargo_scn:PackedScene


func get_next_cargo_scn(structure:CargoStructure) -> PackedScene:
	if structure.get_size() == LaunchSettings.CARGO_TO_FULL-1:
		return top_cargo_scn
	elif structure.get_size() >= 0 and structure.get_size()<LaunchSettings.CARGO_TO_FULL-1:
		var random_idx:int = randi_range(0,main_cargo_parts.size()-1)
		return main_cargo_parts[random_idx]
	else:
		return null
		
func get_random_position_on_surface() -> Vector3:
	# Assuming the MeshInstance3D is assigned to a variable or node reference
	var random_mesh_id:int = randi_range(0,get_child_count()-1)
	var mesh_instance: MeshInstance3D = get_child(random_mesh_id) as MeshInstance3D

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
