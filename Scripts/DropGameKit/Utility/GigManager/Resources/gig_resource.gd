extends Resource
class_name ClubhouseGig

@export var title:String
@export var tag:String
@export_multiline var description:String
@export var visual:Texture2D

@export var mainnet_house_id:String
@export var devnet_house_id:String

@export var link_to_game:String
@export_file(".tscn") var path_to_game_scn:String

func is_external() -> bool:
	return link_to_game.length() > 0
