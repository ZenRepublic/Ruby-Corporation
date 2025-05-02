extends Node
class_name MeshSelector

@export var mesh_options:Array[MeshInstance3D]

func _ready() -> void:
	for mesh in mesh_options:
		mesh.visible=false
		
	var random_mesh_id:int = randi_range(0,mesh_options.size()-1)
	mesh_options[random_mesh_id].visible=true
