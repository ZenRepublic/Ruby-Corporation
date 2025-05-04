extends Node3D
class_name Launchpad

@export var start_drop_height:float = 1
@export var drop_height_increment:float = 0.02

@export var cargo_structure:CargoStructure
@export var base_cargo_scn:PackedScene

@export var death_zone:Node3D
var death_zone_offset:Vector3

var gui:GUI

signal on_setup_complete()
signal on_structure_complete()

func _ready() -> void:
	death_zone_offset = death_zone.position - cargo_structure.position
	cargo_structure.on_height_changed.connect(handle_structure_update)
	
	gui = get_tree().get_first_node_in_group("GUI") as GUI
	
func activate() -> void:
	var base_cargo:Cargo = base_cargo_scn.instantiate()
	await get_tree().process_frame
	cargo_structure.set_base_cargo(base_cargo)
	on_setup_complete.emit()

func get_drop_point() -> Vector3:
	var top_point:Vector3 = cargo_structure.get_highest_point()
#	the top point may not be in the middle. we NEED middle point of the whole structure
	top_point.x = self.global_position.x
	
	var drop_height:float = start_drop_height + drop_height_increment*get_structure_size()
	return top_point + Vector3(0,drop_height,0)

func get_rig_fly_point() -> Vector3:
	return (get_drop_point()+cargo_structure.get_highest_point())/2
	
	
func handle_structure_update() -> void:
	var local_structure_height = to_local(cargo_structure.get_highest_point())
	death_zone.position.y = (local_structure_height + death_zone_offset).y
	gui.admin_panel.update_floor_progress(get_structure_size())
	
	if is_structure_complete():
		on_structure_complete.emit()
		
func get_structure_size() -> int:
	return cargo_structure.curr_cargo.size()
	
func is_structure_complete() -> bool:
	return cargo_structure.curr_cargo.size() == LaunchSettings.CARGO_TO_FULL
