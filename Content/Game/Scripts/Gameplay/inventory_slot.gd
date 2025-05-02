extends Control
class_name InventorySlot

@onready var visual:TextureRect = $Visual
@onready var quantity_label:Label = $Quantity

func setup(item_name:String, img:Texture2D,quantity:int) -> void:
	self.name = item_name
	visual.texture = img
	quantity_label.text = "x%s" % str(quantity)
