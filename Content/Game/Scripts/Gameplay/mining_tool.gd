extends Node2D
class_name MiningTool

enum ToolType{NONE, HAMMER, PICKAXE, CHISEL}

@export var tool_type:ToolType
@export var neutral_visual:Texture2D
@export var hit_visual:Texture2D

@export var energy_cost:int

@export var hit_success_rate:float
@export var hit_pattern:Dictionary = {
	Vector2(0,0):1
}

@onready var animation_player:AnimationPlayer = $AnimationPlayer
@onready var audio_player:SFXManager = $AudioStreamPlayer

@onready var wire_point:Node2D = $Sprite/WirePoint
@export var hit_particles_scn:PackedScene
@export var miss_particles_scn:PackedScene

@export var hit_wait_time:float
@export var shake_strength:float

var is_hitting:bool
signal on_hit_finish

	
func get_hit_cells(grid_pos:Vector2) -> Dictionary:
	var random_value = randf_range(0.0,1.0)
	if hit_success_rate<random_value:
		return {}

	var hit_data:Dictionary
	
	for cell_pos in hit_pattern.keys():
		var damage = hit_pattern[cell_pos]
		hit_data[cell_pos+grid_pos] = damage
	
	return hit_data
	
func play_hit_anim(successful_hit:bool,hit_pos:Vector2) -> void:
	is_hitting = true
	get_parent().global_position = hit_pos
	
	animation_player.animation_finished.connect(finalize_hit,CONNECT_ONE_SHOT)
	animation_player.play("Hit")
	play_sound(successful_hit)
	await get_tree().create_timer(hit_wait_time).timeout
	var particles
	if successful_hit:
		particles = hit_particles_scn.instantiate()
	else:
		particles = miss_particles_scn.instantiate()
		
	var tool_manager:ToolManager = get_parent().get_parent()
	tool_manager.add_child(particles)
	tool_manager.move_child(particles,0)
	particles.global_position = self.global_position
	
func finalize_hit(_anim_name:String) -> void:
	is_hitting=false
	on_hit_finish.emit()
	
func play_sound(success:bool) -> void:
	if success:
		audio_player.play_sound(0)
	else:
		audio_player.play_sound(1)
	
