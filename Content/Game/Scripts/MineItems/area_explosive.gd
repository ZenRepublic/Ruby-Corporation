extends MineItem
class_name AreaExplosive

@export var max_damage:int=9
@export var explode_radius:int=3

@onready var animation_player:AnimationPlayer = $AnimationPlayer

@export var explode_particles_scn:PackedScene
@export var explode_wait_time:float = 0.5
@export var shake_strength:float =  20.0
	
func uncover() -> void:
	super.uncover()
	var player:PlayerManager = get_tree().get_first_node_in_group("Player")
	await player.move_to(self.global_position,focus_zoom_strength,true)
	await explode()
	conclude_uncover()
	
func explode() -> void:
	audio_player.play_sound(0)
	await explode_animation()
	visual.visible=false
	
	var map_manager:MapManager = get_tree().get_first_node_in_group("MapManager")
	var middle_point:Vector2 = get_middle_point()
	var surrounding_tiles:Array[MineTile] = map_manager.get_surrounding_area(middle_point,explode_radius)
	for tile in surrounding_tiles:
		var distance_from_middle:float = sqrt(pow(tile.pos_in_grid.x - middle_point.x, 2) + pow(tile.pos_in_grid.y - middle_point.y, 2))
		var damage:int = lerp(max_damage,ceili(max_damage/float(explode_radius)),distance_from_middle/explode_radius)
		tile.get_hit(damage)
					
func explode_animation() -> void:
	z_index = 1
	animation_player.play("Explode")
	await get_tree().create_timer(explode_wait_time).timeout
	
	var player:PlayerManager = get_tree().get_first_node_in_group("Player")
	player.cam.start_shake(0.5,shake_strength)
	
	var game_manager:GameManager = get_tree().get_first_node_in_group("GameManager")
	game_manager.shockwave_manager.send_shockwave(self.get_global_transform_with_canvas().origin,player.cam,1.6)
	
	if explode_particles_scn!=null:
		var particles = explode_particles_scn.instantiate()
		get_tree().root.get_node("MiningMinigame/ParticlesLayer").add_child(particles)
		#add_child(particles)
		particles.global_position = self.global_position
		particles.z_index = 1
		await get_tree().create_timer(explode_wait_time).timeout
	

func get_middle_point() -> Vector2:
	var sum_position = Vector2()
	for tile in occupied_tiles:
		sum_position += tile.pos_in_grid
	return sum_position / occupied_tiles.size()
