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

@export var local_pck_path:String
@export var url_to_pck:String
@export var main_scn_path:String

func is_external() -> bool:
	return link_to_game.length() > 0
	
func get_url_or_path(local:bool) -> String:
	if local:
		return local_pck_path
	else:
		return url_to_pck
