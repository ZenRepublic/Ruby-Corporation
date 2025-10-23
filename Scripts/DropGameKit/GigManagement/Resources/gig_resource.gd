extends Resource
class_name ClubhouseGig

@export var title:String
@export var tag:String
@export_multiline var description:String
@export var visual:Texture2D

@export var mainnet_house_id:String
@export var devnet_house_id:String

@export var local_pck_path:String
@export var url_to_pck:String

@export var folder_name:String
	
func get_url_or_path(local:bool) -> String:
	if local:
		return local_pck_path
	else:
#		TEMPORARY SOLUTION: get newest game link from server based on the title
		var response:Dictionary = await ClubhouseProgram.server.get_url_to_gig_pck(folder_name)
		if response.has("error"):
			return url_to_pck
		return response["body"]["link"]
		
func get_config_path() -> String:
	return "res://%s/_GigMakerSDK/gig_config.json" % folder_name
	
func get_scene_path() -> String:
	return "res://%s/_GigMakerSDK/GigMaker.tscn" % folder_name
