extends Control
class_name Inventory

@export var inv_slot_scene:PackedScene

@onready var inventory_box:VBoxContainer = $InventoryBox/MarginContainer/VBoxContainer/InventoryContent
@onready var default_move_location:Control = $InventoryBox/MarginContainer/VBoxContainer/BottomHandler/BottomControl/BottomPart

@onready var audio_player:AudioStreamPlayer = $AudioStreamPlayer

		
func refresh_inventory_view() -> void:
	for slot in inventory_box.get_children():
		inventory_box.remove_child(slot)
		slot.queue_free()
	
	var player:PlayerManager = get_tree().get_first_node_in_group("Player")
	var items:Dictionary = player.inventory.get_collected_items()
		
	for key in items.keys():
		var slot:InventorySlot = inv_slot_scene.instantiate()
		inventory_box.add_child(slot)
		slot.setup(key,items[key].icon,items[key].quantity)
	pass
	
func move_item_to_slot(item:Node2D,visual:Texture2D,inv_data:InventoryItem) -> void:
	var player:PlayerManager = get_tree().get_first_node_in_group("Player")
	
	#create texturerect copy of item and place in the correct position
	var canvas_item:TextureRect = TextureRect.new()
	canvas_item.texture = visual
	add_child(canvas_item)	
	var canvas_transform = player.cam.get_canvas_transform()
	
	canvas_item.global_position = item.get_global_transform_with_canvas().origin
	#texturerect origin is on top left corner, so have to substract half its size from position to center
	canvas_item.global_position -= Vector2(visual.get_width()/2.0, visual.get_height()/2.0)
	canvas_item.scale *= player.cam.zoom

	audio_player.stream = inv_data.move_sound
	audio_player.play()
	
	var move_position:Vector2 = canvas_transform.basis_xform(get_item_move_position(inv_data))
	var tween = create_tween()
	#tween.chain().tween_property(canvas_item, "position",move_position, 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	## Interpolate the scale from 1.0 to 2.0 and then to 0.0
	#tween.parallel().tween_property(canvas_item, "scale", canvas_item.scale*3.0*(1-player.cam.get_zoom_strength()), 0.15).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	#tween.tween_property(canvas_item, "scale", Vector2(0.0, 0.0), 0.15).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	tween.chain().tween_property(canvas_item, "position",move_position, 0.3).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	# Interpolate the scale from 1.0 to 2.0 and then to 0.0
	tween.parallel().tween_property(canvas_item, "scale", canvas_item.scale*2*(1-player.cam.get_zoom_strength()), 0.13).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(canvas_item, "scale", Vector2(0.0, 0.0), 0.17).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	refresh_inventory_view()
	
func get_item_move_position(item_data:InventoryItem) -> Vector2:
	if get_slot_by_name(item_data.item_name) != null:
		return get_slot_by_name(item_data.item_name).global_position
	else:
		return default_move_location.global_position
		
	
func get_slot_by_name(item_name:String) -> InventorySlot:
	for slot in inventory_box.get_children():
		if slot.name == item_name:
			return slot
	return null
