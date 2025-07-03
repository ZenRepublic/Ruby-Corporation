extends Node
class_name TensorAPI
	
func setup_tensor() -> void:
	pass

func search_collections(query:String,limit:int=20,page:int=1) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	
	var body:Dictionary = {
		"query":query,
		"limit":limit,
		"page":page
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("tensor/searchcollections"))
	return response


func get_whitelist_info(coll_ids:Array) -> Array:
	var headers:Array = ["Content-type: application/json"]
	
	var body:Dictionary = {
		"collIds":coll_ids,
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("tensor/getwhitelistinfo"))
	if !response.has("body"):
		return []
		
	return response["body"]["data"]
