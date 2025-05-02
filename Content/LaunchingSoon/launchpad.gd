extends Node3D
class_name Launchpad

@export var start_drop_height:float = 1
@export var drop_height_increment:float = 0.02

@export var cargo_structure:CargoStructure
@export var base_cargo_scn:PackedScene

func get_drop_point() -> Vector3:
	var top_point:Vector3 = cargo_structure.get_highest_point()
#	the top point may not be in the middle. we NEED middle point of the whole structure
	top_point.x = self.global_position.x
	
	var drop_height:float = start_drop_height + drop_height_increment*cargo_structure.get_child_count()
	
	return top_point + Vector3(0,drop_height,0)
	
func activate() -> void:
	var base_cargo:Cargo = base_cargo_scn.instantiate()
	await get_tree().process_frame
	cargo_structure.set_base_cargo(base_cargo)
		
	
