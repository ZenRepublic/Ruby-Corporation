extends Node3D

# Adjustable parameters
# Configuration
@export var tether_length: float = 2.0
@export var spring_strength: float = 5.0
@export var damping: float = 0.9
@export var swing_response: float = 0.3


# Internal state
var velocity: Vector3 = Vector3.ZERO       # Magnet's velocity in local space
var target_pos: Vector3

var drone:CarrierDrone

func _ready():
	# Initialize magnet at equilibrium position in local space
	#position = thread_attachment + Vector3(0, -thread_length, 0)
	drone = get_parent() as CarrierDrone

func _process(delta):	
	global_position += velocity * delta

	# The rest position is directly below the drone
	var rest_pos: Vector3 = drone.global_position + Vector3.DOWN * tether_length

	# Apply drone movement influence — magnet lags behind the drone velocity
	var offset_from_drone = global_position - drone.global_position
	var swing_force = -drone.velocity * swing_response
	velocity += swing_force * delta

	# Spring force pulling toward rest position
	var to_rest = rest_pos - global_position
	velocity += to_rest * spring_strength * delta

	# Apply damping to avoid perpetual swing
	velocity *= damping

	# Move the magnet
	global_position += velocity * delta

	face_drone()
	
func face_drone():
	var to_drone = (drone.global_position - global_position).normalized()
	if to_drone.length_squared() == 0:
		return

	var up = Vector3.UP

	# Handle the edge case where to_drone is parallel or nearly parallel to UP
	if abs(to_drone.dot(up)) > 0.99:
		up = Vector3.FORWARD  # fallback if pointing almost straight up/down

	var z_axis = to_drone
	var x_axis = up.cross(z_axis).normalized()
	var y_axis = z_axis.cross(x_axis).normalized()

	var basis = Basis(x_axis, y_axis, z_axis).orthonormalized()

	# Optional: correct for model facing +X instead of +Z
	basis = basis.rotated(Vector3.UP, deg_to_rad(90))

	global_transform.basis = basis
	
