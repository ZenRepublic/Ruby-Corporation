extends Node3D
class_name CargoStructure

@export var max_cargo_drop_amount:int=3
@export var base_spawn_offset:Vector3
@export var sway_speed:float = 1.0
@export var sway_increase_tick:float = 0.5
@export var offset_weight = 0.1 # Weight of offset in amplitude
@export var center_offset_weight = 0.2 # Weight of net offset in shifting pendulum center

var cargo_base:Cargo
var curr_cargo:Array[Dictionary] = []

var total_offset = 0.0
var net_offset = 0.0

var target_sway_amplitude:float = 0
var target_offset_from_center:float = 0

var curr_sway_amplitude:float = 0
var curr_offset_from_center:float = 0

var sway_time:float

signal on_height_changed()

func _process(delta: float) -> void:
	if target_sway_amplitude > 0:
		curr_sway_amplitude = lerp(curr_sway_amplitude, target_sway_amplitude, sway_speed * delta)
		curr_offset_from_center = lerp(curr_offset_from_center, target_offset_from_center, sway_speed * delta)
	
		var sway_delta:float = sin(sway_time*sway_speed) * curr_sway_amplitude
		self.rotation_degrees.z = curr_offset_from_center + sway_delta
		sway_time += delta
	
func set_base_cargo(cargo:Cargo) -> void:
	cargo_base = cargo
	add_child(cargo_base)
	cargo_base.position += Vector3(0,cargo_base.height/2.0,0)
	cargo_base.position += base_spawn_offset
	
func get_placement_tier(cargo:Cargo, collided_cargo:Cargo,hit_pos:Vector3, hit_normal:Vector3) -> LaunchSettings.PLACE_TIER:
	if curr_cargo.size()>0 and collided_cargo != curr_cargo[curr_cargo.size()-1]["cargo"]:
		return LaunchSettings.PLACE_TIER.NONE
		
	var distance_to_center:float = abs(collided_cargo.global_position.x - hit_pos.x)
	var max_distance_to_connect:float = (collided_cargo.width * LaunchSettings.SLOPPY_PLACE_RANGE) / 2.0
	var accuracy:float = abs(distance_to_center) / abs(max_distance_to_connect)
		
	if accuracy <= LaunchSettings.LEGEND_PLACE_RANGE:
		return LaunchSettings.PLACE_TIER.LEGEND
	elif accuracy <= LaunchSettings.BASED_PLACE_RANGE:
		return LaunchSettings.PLACE_TIER.BASED
	elif accuracy <= LaunchSettings.DECENT_PLACE_RANGE:
		return LaunchSettings.PLACE_TIER.DECENT
	elif accuracy <= LaunchSettings.SLOPPY_PLACE_RANGE:
		return LaunchSettings.PLACE_TIER.SLOPPY
	else:
		return LaunchSettings.PLACE_TIER.NONE

	
func apply_cargo(cargo:Cargo) -> void:
	cargo.reparent(self)
	var previous_cargo:Cargo
	if curr_cargo.size() == 0:
		previous_cargo = cargo_base
	else:
		previous_cargo = curr_cargo[curr_cargo.size()-1]["cargo"]
		
	var place_offset:Vector3 = cargo.position-previous_cargo.position
	var cargo_data:Dictionary = {
		"cargo":cargo,
		"place_offset":place_offset.x,
	}
	curr_cargo.append(cargo_data)	
	calculate_sway_strength()
	on_height_changed.emit()
	
func drop_cargo() -> void:
#	get cargo starting from the top and if its placement accuracy is less than 50% drop it
# 	stop if accuracy is higher
	for i in range(max_cargo_drop_amount):
		var top_cargo_idx:int = curr_cargo.size()-1
		if top_cargo_idx < 0:
			break
		var topmost_cargo:Cargo = curr_cargo[top_cargo_idx]["cargo"]
		if topmost_cargo.place_tier < LaunchSettings.PLACE_TIER.BASED:
			curr_cargo.remove_at(top_cargo_idx)
			topmost_cargo.drop_off()
		else:
			break
	on_height_changed.emit()
	
func get_highest_point() -> Vector3:
	var top_cargo:Cargo
	if curr_cargo.size() == 0:
		top_cargo = cargo_base
	else:
		top_cargo = curr_cargo[curr_cargo.size()-1]["cargo"]
	var highest_point:Vector3 = top_cargo.global_position + Vector3(0,top_cargo.height/2,0)
	return highest_point
	
func calculate_sway_strength() -> void:
	total_offset = 0.0
	net_offset = 0.0
	
	for i in range(curr_cargo.size()):
		var place_offset:float = curr_cargo[i]["place_offset"]
		total_offset += abs(place_offset)
#		signed offset to determine leaning side if any
		net_offset += place_offset
		
	target_sway_amplitude = curr_cargo.size() * sway_increase_tick
	target_sway_amplitude += total_offset  * offset_weight
	
	target_offset_from_center = net_offset * center_offset_weight
