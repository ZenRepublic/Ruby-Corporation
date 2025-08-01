extends Node
class_name DanbooruAPI

enum TagRating{Safe, Questionable, Explicit, SFW, All}
	
func setup_danbooru() -> void:
	pass

func search_tags(query:String,rating:TagRating, limit:int=10,page:int=1) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	
	var body:Dictionary = {
		"query":query,
		"limit":limit,
		"page":page,
		#"rating":DanbooruAPI.TagRating.keys()[rating]
	}
	
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("danbooru/searchtags"))
	return response
