extends Node
class_name DropGameSelector

@export var campaign_manager_scn:PackedScene
@export var drop_games:Array[DropGame]

signal on_game_selected()

func _ready() -> void:
	for game in drop_games:
		game.select_button.pressed.connect(pop_campaign_manager)

func pop_campaign_manager(mainnet_key:String,devnet_key:String) -> void:
	ClubhouseProgram.utils.set_house_data(mainnet_key,devnet_key)
	on_game_selected.emit()
