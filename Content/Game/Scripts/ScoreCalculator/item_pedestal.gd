extends Node
class_name ItemPedestal

@export var showcase_item_scn:PackedScene
@onready var item_container:HBoxContainer = $PedestalLight/Container

@onready var animation_player:AnimationPlayer  = $AnimationPlayer

@onready var light_animation_player:AnimationPlayer = $PedestalLight/AnimationPlayer

func showcase_items(inv_data:Dictionary) -> void:
	animation_player.play("Appear")
	await get_tree().create_timer(0.7).timeout
	light_animation_player.play("Pulsate")
	
	var items:Array[ShowcaseItem]
	
	for key in inv_data.keys():
		var item:InventoryItem = inv_data[key]
		for i in range(item.quantity):
			var instance:ShowcaseItem = showcase_item_scn.instantiate()
			instance.setup(item.visual)
			items.append(instance)
			
	items.shuffle()
	for item in items:
		item_container.add_child(item)
		item.drop()
		await get_tree().create_timer(0.2).timeout
	
