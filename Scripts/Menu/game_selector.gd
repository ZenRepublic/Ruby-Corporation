extends Node
class_name GameSelector

@export var drop_games:Array[DropGame]

var active_game:DropGame=null

signal on_game_selected(game:DropGame)

func _ready() -> void:
	for game in drop_games:
		game.on_selected.connect(select_game)
		
func select_game(game:DropGame) -> void:
	active_game = game
	ClubhouseProgram.utils.set_house_data(game.mainnet_house_key,game.devnet_house_key)
	on_game_selected.emit(game)
	
func get_active_game() -> DropGame:
	return active_game
	
