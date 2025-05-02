extends Node
class_name PlayerInventory

@export var max_unit_quantity:int = 99
var items_collected:Dictionary


func add_to_inventory(item:InventoryItem) -> void:
	var item_id:String = item.item_name
	var new_item:bool = item_id not in items_collected.keys()
	
	if new_item:
		items_collected[item_id] = item.duplicate()
	else:
		items_collected[item_id].quantity = clamp(items_collected[item_id].quantity+item.quantity,0,max_unit_quantity)
		
func get_collected_items() -> Dictionary:
	return items_collected
	
func clear_items() -> void:
	items_collected = {}
