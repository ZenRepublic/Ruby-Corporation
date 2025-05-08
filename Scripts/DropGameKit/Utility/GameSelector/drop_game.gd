extends Node
class_name DropGame

@export var mainnet_house_key:String
@export var devnet_house_key:String
@export var select_button:BaseButton

@export_file(".tscn") var game_scene_path:String

signal on_selected(game:DropGame)

func _ready() -> void:
	select_button.pressed.connect(select)
	
func select() -> void:
	on_selected.emit(self)
