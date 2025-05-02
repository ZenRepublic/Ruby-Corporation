extends Node3D
class_name Launchpad

@export var start_drop_height:float = 1
@export var drop_height_increment:float = 0.02

@export var cargo_structure:CargoStructure

func get_drop_point() -> Vector3:
	var drop_height:float = start_drop_height + drop_height_increment*cargo_structure.get_child_count()
	
	var top_point:Vector3 = cargo_structure.get_top_point()
#	the top point may not be in the middle. we NEED middle point of the whole structure
	top_point.x = self.global_position.x
	
	return top_point + Vector3(0,drop_height,0)
		
	
