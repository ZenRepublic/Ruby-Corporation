extends Node3D
class_name CargoStructure

var launchpad:Launchpad

var cargo_base:Cargo
var curr_cargo:Array[Cargo] = []

signal on_cargo_placed(cargo:Cargo)

func _ready() -> void:
	launchpad = self.get_parent() as Launchpad
	
func set_base_cargo(cargo:Cargo) -> void:
	cargo_base = cargo
	add_child(cargo_base)
	cargo_base.position += Vector3(0,cargo_base.height/2.0,0)
	
func apply_cargo(cargo:Cargo,placement_score:int=0) -> void:
	curr_cargo.append(cargo)
	cargo.reparent(self)
	await cargo.on_connected
	on_cargo_placed.emit(cargo,placement_score)
	
func get_size() -> int:
	return curr_cargo.size()
	
func get_placement_score(cargo:Cargo, collided_cargo:Cargo,hit_pos:Vector3, hit_normal:Vector3) -> int:
	if get_size()>0 and collided_cargo != curr_cargo[curr_cargo.size()-1]:
		return 0
		
	var distance_to_center:float = abs(collided_cargo.global_position.x - hit_pos.x)
#	check if good enough to connect
	var max_distance_to_connect:float = (collided_cargo.width * LaunchSettings.MAX_PLACE_ACCURACY) / 2.0
	if distance_to_center > max_distance_to_connect:
		return 0
		
	#calculate accuracy
	var accuracy:float = 1 - abs(distance_to_center) / abs(max_distance_to_connect)
	var placement_score:int = ceili(lerpf(0,LaunchSettings.MAX_PLACEMENT_SCORE,accuracy))

#	check if maybe a perfect connect
#	divide by 2 because positive/negative distance
	var max_distance_to_perfect:float = (collided_cargo.width * LaunchSettings.MAX_PERFECT_PLACE_ACCURACY) / 2.0
	if distance_to_center <= max_distance_to_perfect:
		return LaunchSettings.get_max_placement_score()

	return placement_score
	
func get_highest_point() -> Vector3:
	var top_cargo:Cargo
	if curr_cargo.size() == 0:
		top_cargo = cargo_base
	else:
		top_cargo = curr_cargo[curr_cargo.size()-1]
	var highest_point:Vector3 = top_cargo.global_position + Vector3(0,top_cargo.height/2,0)
	return highest_point
	
func is_started() -> bool:
	return cargo_base!=null
	
func is_complete() -> bool:
	return get_size() == LaunchSettings.CARGO_TO_FULL
