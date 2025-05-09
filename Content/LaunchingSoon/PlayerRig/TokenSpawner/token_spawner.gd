extends Node3D
class_name TokenSpawner

@export var token_scn:PackedScene
@export var spawn_point:Node3D
@export var spawn_radius:float = 1
@export var max_token_send_amount:int = 20

@export var send_duration:float = 0.6

@export var default_token_visual:Texture2D

var token_pool:Array[DisplayToken]

var is_sending:bool=false

signal on_toked_arrived(token_value:float)
signal on_send_finished()

func setup_token_pool(custom_token_visual:Texture2D=null) -> void:
	for i in range(max_token_send_amount):
		var token:DisplayToken = token_scn.instantiate() as DisplayToken
		add_child(token)
		token.on_target_reached.connect(return_token_to_pool)
		token.set_visual(custom_token_visual)
		token.visible=false
		token_pool.append(token)
		
func grab_token_from_pool() -> DisplayToken:
	for i in range(token_pool.size()):
		if token_pool[i]!=null:
			var token:DisplayToken = token_pool[i]
			token_pool[i] = null
			token.visible=true
			return token
	return null
	
func return_token_to_pool(token:DisplayToken) -> void:
	for i in range(token_pool.size()):
		if token_pool[i]==null:	
			token.visible=false
			token.position = Vector3.ZERO
			token.rotation = Vector3.ZERO
			token_pool[i] = token
			on_toked_arrived.emit(token.value)
			return
			

func send_tokens(tokens_earned:float, target:Node3D) -> void:
	is_sending=true
	# Adjust increment based on difference size for consistent animation speed
	var send_amount: int = (tokens_earned/LaunchSettings.get_max_placement_score())*max_token_send_amount
	var token_value:float = tokens_earned/send_amount
	token_value = snappedf(token_value,0.01)
	for i in range(send_amount):
		var token:DisplayToken = grab_token_from_pool()
		# Store initial position
		var random_angle = randf() * 2 * PI  # Random angle in radians (0 to 2π)
		token.global_position = spawn_point.global_position + Vector3(
			cos(random_angle) * spawn_radius,
			sin(random_angle) * spawn_radius,
			0  # Keep Z at target's Z for XY plane circle
		)
		
		token.move_to_target(token_value,target,send_duration)
		await get_tree().create_timer(0.04).timeout
		
	await get_tree().create_timer(send_duration).timeout
	is_sending=false
	on_send_finished.emit()
		
