extends MineItem
class_name Battery

@export var energy_to_restore:int=30

@onready var animation_player:AnimationPlayer = $AnimationPlayer

var used_up:bool=false

func _process(delta: float) -> void:
	if used_up:
		visual.global_position = $Path2D/PathFollow2D.global_position
		visual.rotate(delta*30.0)

func uncover() -> void:
	super.uncover()
	var player:PlayerManager = get_tree().get_first_node_in_group("Player")
	await player.move_to(self.global_position,focus_zoom_strength,true)
	
	var power_world_pos = get_viewport().get_canvas_transform().affine_inverse() * player.hud.powerbank.battery_point.global_position
	z_index=1
	var canvas_layer:CanvasLayer = CanvasLayer.new()
	get_tree().current_scene.add_child(canvas_layer)
	canvas_layer.layer = 99
	#self.reparent(canvas_layer)
	
	animation_player.play("Discover")
	audio_player.play_sound(0)
	await get_tree().create_timer(0.35).timeout
	var tween = create_tween()
	tween.tween_property(self, "position",power_world_pos, 0.4).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "scale",Vector2(1.4,1.4), 0.4).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	animation_player.play("Restore")
	audio_player.play_sound(1)
	
	await get_tree().create_timer(0.25).timeout
	player.stats.restore_energy(energy_to_restore)

	conclude_uncover()
	
func destroy() -> void:
	used_up=true
	var tween = create_tween()
	tween.tween_property($Path2D/PathFollow2D,"progress_ratio",1.0, 0.7).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	queue_free()
