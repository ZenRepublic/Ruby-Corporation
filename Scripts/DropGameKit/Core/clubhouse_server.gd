extends Node
class_name ClubhouseServer

@export var SERVER_LINK:String = "https://rubians-server-625d2ae63a81.herokuapp.com/"
@export var use_localhost:bool=false
@export var localhost_port:int = 5000
		
func is_set() -> bool:
	return get_server_link().length() > 0
	
func get_server_link(slug:String="") -> String:
	var base_link:String
	if use_localhost:
		base_link = "http://localhost:%s/" % str(localhost_port)
	else:
		base_link = SERVER_LINK
	return base_link + slug
	
func add_oracle_signature(transaction:Transaction) -> PackedByteArray:
	var serialized_tx:PackedByteArray = transaction.serialize()
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"transaction":serialized_tx
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,get_server_link("clubhouse/sign"))
	if response.has("error"):
		push_error("failed to receive signature by the server. ",response)
		return []
		
	return response["body"]["transaction"]["data"]

func set_player_data(house_key:Pubkey,campaign_key:Pubkey,player_key:Pubkey,data:Dictionary) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"house_id":house_key.to_string(),
		"campaign_id":campaign_key.to_string(),
		"player_id":player_key.to_string(),
		"data":data
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,get_server_link("clubhouse/setplayerdata"))
	return response
	
func get_player_data(house_key:Pubkey,campaign_key:Pubkey,player_key:Pubkey) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	var url:String = get_server_link()+"clubhouse/getplayerdata?"
	url += "house_id=%s&" % house_key.to_string()
	url += "campaign_id=%s&" % campaign_key.to_string()
	url += "player_id=" + player_key.to_string()
		
	var response:Dictionary = await HttpRequestHandler.send_get_request(url,true,headers)
	if response.has("error"):
		return response
	
	return response["body"]["data"]
		
	
func delete_campaign_data(house_key:Pubkey,campaign_key:Pubkey) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"house_id":house_key.to_string(),
		"campaign_id":campaign_key.to_string(),
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,get_server_link("clubhouse/deletecampaign"))
	return response
