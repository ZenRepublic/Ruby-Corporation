extends Camera3D
class_name CamController

@export var shake_strength: float = 20.0
@export var shake_duration: float = 0.5
@export var shake_frequency: float = 20.0

@export var max_knockback_strength:float = 0.8
@export var knockback_duration:float = 0.5

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
	
func knock_back(point_of_action:Vector3, knock_back_power:float) -> void:
	var dir_to_point:Vector3 = (to_local(point_of_action) - self.position).normalized()
	original_position = self.position
	var knockback_strength = lerpf(max_knockback_strength/5.0,max_knockback_strength,knock_back_power)
	var knockback_target_point:Vector3 = original_position - (dir_to_point*knockback_strength)
	var tween:Tween = create_tween()
	tween.tween_property(self,"position",knockback_target_point,knockback_duration*0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self,"position",original_position,knockback_duration*0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
