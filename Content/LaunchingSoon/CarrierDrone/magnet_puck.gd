extends Node3D
class_name MagnetPuck

@export var spawn_point:Node3D
# Adjustable parameters
# Configuration
@export var tether_length: float = 2.0
@export var spring_strength: float = 5.0
@export var damping: float = 0.9
@export var swing_intertia:float = 0.3


# Internal state
var velocity: Vector3 = Vector3.ZERO       # Magnet's velocity in local space
var target_pos: Vector3

var drone:CarrierDrone

func _ready():
	# Initialize magnet at equilibrium position in local space
	#position = thread_attachment + Vector3(0, -thread_length, 0)
	drone = get_parent() as CarrierDrone

func _process(delta):	
	# Target point below drone by rope length
	var desired_position = drone.global_transform.origin - drone.global_transform.basis.y * tether_length

	# Apply a spring force toward the desired hanging position
	var force = (desired_position - global_transform.origin) * spring_strength
	velocity += force * delta

	# Add some inertia based on drone velocity
	velocity += drone.velocity * swing_intertia * delta

	# Apply damping to smooth out the motion
	velocity -= velocity * damping * delta

	# Move the puck based on velocity
	global_transform.origin += velocity * delta
	apply_rotation()
	
	
	
func apply_rotation():
	var to_drone = (drone.global_position - global_position).normalized()
	if to_drone.length_squared() == 0:
		return

	var up = Vector3.UP
	if abs(to_drone.dot(up)) > 0.99:
		up = Vector3.FORWARD

	var z_axis = to_drone
	var x_axis = up.cross(z_axis).normalized()
	var y_axis = z_axis.cross(x_axis).normalized()

	var look_basis = Basis(x_axis, y_axis, z_axis).orthonormalized()

	# Rotate basis -90° around X to remap Z-forward to Y-forward
	var correction = Basis(-Vector3.RIGHT, deg_to_rad(-90))
	var final_basis = look_basis * correction

	# Smoothly rotate using slerp to prevent jumps
	var current_quat = global_transform.basis.get_rotation_quaternion()
	var target_quat = final_basis.get_rotation_quaternion()
	var smooth_quat = current_quat.slerp(target_quat, 0.1)  # 0.1 = smoothing factor

	global_transform.basis = Basis(smooth_quat)
	

	
