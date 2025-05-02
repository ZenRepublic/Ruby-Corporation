extends MineItem
class_name LineExplosive
enum ExplodeDirection {Horizontal,Vertical}

@export var explosion_direction:ExplodeDirection
@export var max_damage:int=3

@onready var animation_player:AnimationPlayer = $AnimationPlayer

@export var explode_particles_scn:PackedScene
@export var tile_destroy_particles_scn:PackedScene
@export var explode_wait_time:float = 0.4
@export var tile_destroy_sequence_time:float = 0.2
@export var shake_strength:float = 10.0

	
func uncover() -> void:
	super.uncover()
	var player:PlayerManager = get_tree().get_first_node_in_group("Player")
	await player.move_to_center(true)
	await explode()
	conclude_uncover()
	
func explode() -> void:
	audio_player.play_sound(0)
	await explode_animation()
	visual.visible=false
	
	var map_manager:MapManager = get_tree().get_first_node_in_group("MapManager")
	
	var explode_tile_sequence:Array
	
	var tile_check_direction:Vector2
	if explosion_direction == ExplodeDirection.Vertical:
		tile_check_direction = Vector2(0,1)
	elif explosion_direction == ExplodeDirection.Horizontal:
		tile_check_direction = Vector2(1,0)
		
	explode_tile_sequence.append(occupied_tiles)
	while true:
		var next_tiles_to_explode:Array
		#get tile up and down from the previous one
		var prev_tile0:MineTile = explode_tile_sequence[explode_tile_sequence.size()-1][0]
		if prev_tile0 != null and !is_edge(prev_tile0.pos_in_grid):
			next_tiles_to_explode.append(map_manager.get_topmost_active_tile_at_position(prev_tile0.pos_in_grid+tile_check_direction*-1))
		else:
			next_tiles_to_explode.append(null)
			
		var prev_tile1:MineTile = explode_tile_sequence[explode_tile_sequence.size()-1][1]
		if prev_tile1 != null and !is_edge(prev_tile1.pos_in_grid):
			next_tiles_to_explode.append(map_manager.get_topmost_active_tile_at_position(prev_tile1.pos_in_grid+tile_check_direction))
		else:
			next_tiles_to_explode.append(null)
			
		
		#if theres at least one tile in the next tiles to explode, continue until theres none, then break out of loop
		var has_tiles:bool=false
		for tile in next_tiles_to_explode:
			if tile!=null:
				has_tiles=true
				break
				
		if has_tiles:
			explode_tile_sequence.append(next_tiles_to_explode)
		else:
			break
			
	for tiles in explode_tile_sequence:
		for tile in tiles:
			if tile!=null:
				if tile_destroy_particles_scn!=null:
					var particles:CPUParticles2D = tile_destroy_particles_scn.instantiate()
					get_tree().root.get_node("MiningMinigame/ParticlesLayer").add_child(particles)
					particles.global_position = tile.global_position
					particles.z_index = 1
					await get_tree().create_timer(tile_destroy_sequence_time/2.0).timeout
				tile.get_hit(max_damage)
		await get_tree().create_timer(tile_destroy_sequence_time).timeout
					
func explode_animation() -> void:
	z_index = 1
	animation_player.play("Explode")
	await get_tree().create_timer(explode_wait_time).timeout
	
	var player:PlayerManager = get_tree().get_first_node_in_group("Player")
	player.cam.start_shake(0.5,shake_strength)
	
	var game_manager:GameManager = get_tree().get_first_node_in_group("GameManager")
	game_manager.shockwave_manager.send_shockwave(self.get_global_transform_with_canvas().origin,player.cam,1.2)
	if explode_particles_scn!=null:
		var particles:CPUParticles2D = explode_particles_scn.instantiate()
		get_tree().root.get_node("MiningMinigame/ParticlesLayer").add_child(particles)
		#add_child(particles)
		particles.global_position = self.global_position
		particles.z_index = 1
		await get_tree().create_timer(explode_wait_time).timeout
		
func is_edge(pos:Vector2) -> bool:
	var map_manager:MapManager = get_tree().get_first_node_in_group("MapManager")
	
	if explosion_direction == ExplodeDirection.Vertical:
		return pos.y == 0 || pos.y == map_manager.map_height-1
	elif explosion_direction == ExplodeDirection.Horizontal:
		return pos.x == 0 || pos.x == map_manager.map_width-1
	else:
		return false
	
