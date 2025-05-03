extends Camera3D
class_name CamController

@export var shake_strength: float = 20.0
@export var shake_duration: float = 0.5
@export var shake_frequency: float = 20.0

var shake_timer: float = 0.0
var original_position: Vector3
var time_since_last_shake: float = 0.0

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta
		time_since_last_shake += delta

		# Only update the position based on the frequency
		if time_since_last_shake >= 1.0 / shake_frequency:
			time_since_last_shake = 0.0

			# Calculate a random offset
			var offset_x = (randf() * 2 - 1) * shake_strength
			var offset_y = (randf() * 2 - 1) * shake_strength
			position = original_position + Vector3(offset_x, offset_y,0)

		# Stop the shake if the timer has expired
		if shake_timer <= 0:
			position = original_position

# Function to start the screen shake
func start_shake(duration: float = -1.0, strength: float = -1.0, frequency: float = -1.0):
	if duration > 0:
		shake_duration = duration
	if strength > 0:
		shake_strength = strength
	if frequency > 0:
		shake_frequency = frequency
	shake_timer = shake_duration
	time_since_last_shake = 0.0
	original_position = position
