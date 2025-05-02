extends Node

@export var use_localhost:bool=false
@export var localhost_port:int = 5000

var SERVER_LINK:String = "https://rubians-server-625d2ae63a81.herokuapp.com/"

func _ready() -> void:
	if use_localhost:
		SERVER_LINK = "http://localhost:%s/" % str(localhost_port)

func register_user(user:Pubkey) -> void:
	if user == null:
		push_error("User not found")
		return
		
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"walletAddress":user.to_string()
	}
	var _response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,SERVER_LINK+"users/register")

func set_clubhouse_player_data(house_key:Pubkey,campaign_key:Pubkey,player_key:Pubkey,data:Dictionary) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"house_id":house_key.to_string(),
		"campaign_id":campaign_key.to_string(),
		"player_id":player_key.to_string(),
		"data":data
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,SERVER_LINK+"clubhouse/setplayerdata")
	return response
	
func get_clubhouse_player_data(house_key:Pubkey,campaign_key:Pubkey,player_key:Pubkey) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	var url:String = SERVER_LINK+"clubhouse/getplayerdata?"
	url += "house_id=%s&" % house_key.to_string()
	url += "campaign_id=%s&" % campaign_key.to_string()
	url += "player_id=" + player_key.to_string()
		
	var response:Dictionary = await HttpRequestHandler.send_get_request(url,true,headers)
	return response
	
func delete_clubhouse_campaign(house_key:Pubkey,campaign_key:Pubkey) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"house_id":house_key.to_string(),
		"campaign_id":campaign_key.to_string(),
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,SERVER_LINK+"clubhouse/deletecampaign")
	return response
