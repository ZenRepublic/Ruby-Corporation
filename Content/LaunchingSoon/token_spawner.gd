extends Node3D
class_name TokenSpawner

@export var token_scn:PackedScene
@export var spawn_point:Node3D
@export var spawn_radius:float = 1
@export var max_token_send_amount:int = 20

@export var fly_duration:float = 0.5
@export var arc_height: float = 50.0

var token_pool:Array[Sprite3D]

signal on_toked_arrived(token_value:float)

func setup_token_pool(token_visual:Image) -> void:
	for i in range(max_token_send_amount):
		var token:Sprite3D = token_scn.instantiate() as Sprite3D
		add_child(token)
		token.texture = ImageTexture.create_from_image(token_visual)
		token.visible=false
		token_pool.append(token)
		
func grab_token_from_pool() -> Sprite3D:
	for i in range(token_pool.size()):
		if token_pool[i]!=null:
			var token:Sprite3D = token_pool[i]
			token_pool[i] = null
			token.visible=true
			return token
	return null
	
func return_token_to_pool(token:Sprite3D) -> void:
	for i in range(token_pool.size()):
		if token_pool[i]==null:	
			token.visible=false
			token.position = Vector3.ZERO
			token.rotation = Vector3.ZERO
			token_pool[i] = token
			return
			

func send_tokens(tokens_earned:float, destination:Vector3) -> void:
	# Adjust increment based on difference size for consistent animation speed
	var send_amount: int = (tokens_earned/LaunchSettings.get_max_placement_score())*max_token_send_amount
	var token_value:float = tokens_earned/send_amount
	token_value = snappedf(token_value,0.02)
	for i in range(send_amount):
		move_to_destination(grab_token_from_pool(),destination,token_value)
		await get_tree().create_timer(0.05).timeout
		
		
func move_to_destination(token:Sprite3D, target_position:Vector3, token_value:float) -> void:
		# Create tween
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Store initial position
	var random_angle = randf() * 2 * PI  # Random angle in radians (0 to 2π)
	token.global_position = spawn_point.global_position + Vector3(
		cos(random_angle) * spawn_radius,
		sin(random_angle) * spawn_radius,
		0  # Keep Z at target's Z for XY plane circle
	)
	
	# Calculate offset to determine arc direction
	var offset = target_position - token.global_position

	# Determine control point for parabolic arc
	# If x_start < x_target, arc leans outward (e.g., left if moving right)
	var mid_point = (token.global_position + target_position) / 2
	var arc_direction = Vector3.ZERO
	if abs(offset.x) > 0.001:  # Avoid division by zero
		arc_direction.x = -sign(offset.x) * arc_height * 0.5  # Lean opposite to movement
	arc_direction.y = arc_height  # Upward arc (positive Y in 3D)
	var control_point = mid_point + arc_direction

	# Number of steps for smooth arc
	var steps = 20
	var points = []
	# Generate points along quadratic Bezier curve
	for i in range(steps + 1):
		var t = float(i) / steps
		# Quadratic Bezier: P(t) = (1-t)^2*P0 + 2*(1-t)*t*P1 + t^2*P2
		var point = (1-t)*(1-t)*token.global_position + 2*(1-t)*t*control_point + t*t*target_position
		points.append(point)

	# Tween through the points
	for i in range(1, points.size()):
		var point = points[i]
		var step_duration = fly_duration / steps
		tween.tween_property(token, "global_position", point, step_duration)
	#tween.tween_property(token, "global_position", target_position, fly_duration)
	await tween.finished
	return_token_to_pool(token)
	on_toked_arrived.emit(token_value)
	
