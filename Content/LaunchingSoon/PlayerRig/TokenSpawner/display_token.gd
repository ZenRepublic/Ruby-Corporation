extends Node3D
class_name DisplayToken

@export var arc_height: float = 0.5

var follow_target:Node3D
var move_duration:float

var value:float

var start_position: Vector3
var control_point: Vector3
var t := 0.0

var timer:float = 0.0

signal on_target_reached(token:DisplayToken)

func _process(delta: float) -> void:
	if follow_target == null:
		return

	timer += delta
	t = clamp(timer / move_duration, 0.0, 1.0)

	var current_end = follow_target.global_position
	var mid_point = (start_position + current_end) * 0.5
	control_point = mid_point + Vector3(0, arc_height, 0)

	# Quadratic Bezier formula
	var one_minus_t = 1.0 - t
	var bezier_point =one_minus_t * one_minus_t * start_position +2.0 * one_minus_t * t * control_point +t * t * current_end

	self.global_position = bezier_point
	
	if t >= 1.0:
		self.global_position = current_end
		on_target_reached.emit(self)
		follow_target = null

func move_to_target(value:float, target_point:Node3D, move_duration:float=1.0) -> void:
	self.value = value
	follow_target = target_point
	self.move_duration = move_duration
	start_position = self.global_position
	timer = 0.0
	t = 0.0
	
