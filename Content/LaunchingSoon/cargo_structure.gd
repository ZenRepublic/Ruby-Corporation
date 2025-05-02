extends Node3D
class_name CargoStructure

var launchpad:Launchpad

var cargo_base:Cargo
var curr_cargo:Array[Cargo] = []

signal on_cargo_placed(cargo:Cargo)

func _ready() -> void:
	launchpad = self.get_parent() as Launchpad

func handle_collision_with_cargo(cargo:Cargo, collided_cargo:Cargo,hit_pos:Vector3, hit_normal:Vector3) -> void:
#	if not the topmost cargo, ignore
	if get_size()>0 and collided_cargo != curr_cargo[curr_cargo.size()-1]:
		return
		
	var distance_to_center:float = abs(collided_cargo.global_position.x - hit_pos.x)
#	check if good enough to connect
	var max_distance_to_connect:float = (collided_cargo.width * LaunchSettings.MAX_PLACE_ACCURACY) / 2.0
	if distance_to_center > max_distance_to_connect:
		return
		
#	calculate accuracy
	var accuracy:float = 1 - abs(distance_to_center) / abs(max_distance_to_connect)
	var placement_score:int = ceili(lerpf(0,LaunchSettings.MAX_PLACEMENT_SCORE,accuracy))
		
#	check if maybe a perfect connect
#	divide by 2 because positive/negative distance
	var max_distance_to_perfect:float = (collided_cargo.width * LaunchSettings.MAX_PERFECT_PLACE_ACCURACY) / 2.0
	if distance_to_center <= max_distance_to_perfect:
		var stick_pos:Vector3 = collided_cargo.global_position + Vector3(0,collided_cargo.height,0)
		placement_score = LaunchSettings.get_max_placement_score()
		cargo.stick_on_structure(stick_pos,true)
	else:
		var stick_pos:Vector3 = hit_pos + Vector3(0, collided_cargo.height / 2.0, 0) # Offset by half height
		cargo.stick_on_structure(stick_pos)
	
	cargo.set_placement_score(placement_score)
	apply_cargo(cargo,placement_score)
	
func apply_cargo(cargo:Cargo,placement_score:int=0) -> void:
	if cargo_base==null:
		self.global_position = cargo.global_position - Vector3(0,cargo.height/2,0)
		cargo_base = cargo
	else:
		curr_cargo.append(cargo)
		
	cargo.reparent(self)
	on_cargo_placed.emit(cargo,placement_score)
	
func get_size() -> int:
	return curr_cargo.size()
	
func get_top_point() -> Vector3:
	if cargo_base == null:
		return self.global_position
	
	var top_cargo:Cargo
	if curr_cargo.size() == 0:
		top_cargo = cargo_base
	else:
		top_cargo = curr_cargo[curr_cargo.size()-1]
	return top_cargo.get_top_point()
	
func is_started() -> bool:
	return cargo_base!=null
	
func is_complete() -> bool:
	return get_size() == LaunchSettings.CARGO_TO_FULL
