extends Control
class_name BillSlot

@onready var visual:TextureRect = $Visual
@onready var quantity_label:Label = $Quantity
@onready var token_value_label:NumberLabel = $TokenValue

@onready var token_visual:TextureRect = $TokenVisual

@onready var animation_player:AnimationPlayer = $AnimationPlayer

var total_value:float

func _ready() -> void:
	token_value_label.set_value(0)
	

func setup(bill_creator:BillCreator,item_data:InventoryItem, unit_token_price:float,token_texture:Texture2D=null) -> void:
	visual.texture = item_data.icon
	if token_texture!=null:
		token_visual.texture = token_texture
		
	quantity_label.text = "x %s" % str(item_data.quantity)
	
	animation_player.play("Show")
	await get_tree().create_timer(0.4).timeout
	
	total_value = unit_token_price * item_data.market_value * item_data.quantity
	var rise_increment:float = total_value/10.0
	var curr_value:float=0
	while curr_value<total_value:
		curr_value += rise_increment
		curr_value = clamp(curr_value,0,total_value)
		token_value_label.set_value(curr_value)
		bill_creator.play_increment_sound(lerp(0.9,1.2,curr_value/total_value))
		await get_tree().create_timer(0.07).timeout
		
func get_total_value() -> float:
	return total_value
