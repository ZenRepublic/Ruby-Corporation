extends Node
class_name TensorAPI

@export var API_KEY:String
var tensor_link:String = "https://api.mainnet.tensordev.io/api/v1/"
var headers:PackedStringArray

func _ready() -> void:
	headers = ["accept: application/json", "x-tensor-api-key: "+ API_KEY]

func search_collections(query:String,limit:int=20,page:int=1) -> Dictionary:
	var slug:String = "collections/search_collections"
	var filter:String="?"
	filter+="query=%s" % query
	filter+="&sortBy=%s" % "statsV2.volume24h%3Adesc"
	filter+="&limit=%s" % str(limit)
	filter+="&page=%s" % str(page)
	
	var response:Dictionary
	while true:
		response = await HttpRequestHandler.send_get_request(tensor_link+slug+filter,true,headers)
		if response.size()==0:
			continue
		break
	return response["body"]
	
func get_mint_list(coll_id:String,limit:int=1000) -> Array:
	var slug:String = "collections/list"
	var filter:String="?"
	filter+="collId=%s" % coll_id
	filter+="&limit=%s" % str(limit)
	print(tensor_link+slug+filter)
	var response:Dictionary
	while true:
		response = await HttpRequestHandler.send_get_request(tensor_link+slug+filter,true,headers)
		if response.size()==0:
			continue
		break
	
	var mint_list:Array = response["body"]
	return mint_list

func get_whitelist_info(coll_ids:Array) -> Array:
	var slug:String = "sdk/whitelist_info"
	var filter:String="?"
	
	var index:int=0
	for coll_id in coll_ids:
		if index>0:
			filter+="&"
		filter+="collIds=%s" % coll_id
		index += 1
	var response:Dictionary
	while true:
		response = await HttpRequestHandler.send_get_request(tensor_link+slug+filter,true,headers)
		if response.size()==0:
			continue
		break
	
	return response["body"]
