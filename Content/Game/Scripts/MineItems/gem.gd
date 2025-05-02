extends MineItem
class_name Gem

@export var particles:CPUParticles2D
@export var inventory_item:InventoryItem

func uncover() -> void:
	super.uncover()
	var player:PlayerManager = get_tree().get_first_node_in_group("Player")
	player.inventory.add_to_inventory(inventory_item)
	
	await player.move_to(self.global_position,focus_zoom_strength,true)
	
	await show_effect()
	conclude_uncover()
	
func show_effect() -> void:
	#to make it go above all the tiles	
	z_index = 1
	
	if particles!=null:
		particles.emitting = true
		
	audio_player.play_sound(0)
	
	var tween = create_tween()
	#flash 2 times	
	tween.tween_method(process_flash,0,1,0.1)
	tween.tween_method(process_flash,1,0,0.1)
	tween.tween_method(process_flash,0,1,0.1)
	tween.tween_method(process_flash,1,0,0.1)
	tween.chain().tween_method(process_flash,0.0,0.5,0.15)
	#tween.chain().tween_property(self,"scale",Vector2(1.6,1.6),0.15).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_method(process_shine,0.0,1.0,0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_method(process_flash,0.5,0.0,0.15)
	#tween.chain().tween_property(self,"scale",Vector2(1.0,1.0),0.15).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	#tween.parallel().tween_method(process_shine,0.0,1.0,0.3)
	await tween.finished

func process_flash(value:float) -> void:
	var mat:ShaderMaterial = visual.material
	mat.set_shader_parameter("flash_value",value)
	
func process_shine(value:float) -> void:
	var mat:ShaderMaterial = visual.material
	mat.set_shader_parameter("shine_progress",value)
	
func destroy() -> void:
	var player:PlayerManager = get_tree().get_first_node_in_group("Player")
	#await player.move_to_center(true)
	visual.visible=false
	await player.hud.inventory.move_item_to_slot(self,visual.texture,inventory_item)
	queue_free()
	
