extends Node
class_name ActionButtonBox

@export var actions:Array[BaseButton]

signal on_action_selected(action_id:int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(actions.size()):
		actions[i].pressed.connect(select_action.bind(i))

	
func select_action(action_id:int) -> void:
	on_action_selected.emit(action_id)
	
