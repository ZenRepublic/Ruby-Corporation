extends AccountDisplayEntry
class_name SimpleSelectAccount

@export var label:Label
@export var label_dict_field:String
@export var button:BaseButton

func _ready() -> void:
	if button!=null:
		button.disabled=true
		
func setup_account_entry(id:String,account_data:Dictionary,index:int) -> void:
	super.setup_account_entry(id,account_data,index)

	label.text = account_data[label_dict_field]

	button.pressed.connect(select)
	button.disabled=false

func select() -> void:
	on_selected.emit(self)
