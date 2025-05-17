extends Node

@export var SERVER_LINK:String = "https://rubians-server-625d2ae63a81.herokuapp.com/"
@export var WEBSOCKET_LINK:String = "wss://rubians-server-625d2ae63a81.herokuapp.com/"

@export var use_localhost:bool=false
@export var localhost_port:int = 5000

@export var data_uploader:DataUploader
@export var nosana_manager:NosanaManager
@export var database_manager:DatabaseManager

func _ready() -> void:	
	data_uploader.setup_data_uploader()
	database_manager.setup_database_manager()
	nosana_manager.setup_nosana_manager()
	
func get_request_link(slug:String="") -> String:
	var base_link:String
	if use_localhost:
		base_link = "http://localhost:%s/" % str(localhost_port)
	else:
		base_link = SERVER_LINK 
	return base_link + slug
	
func get_websocket_link(slug:String="") -> String:
	var base_link:String
	if use_localhost:
		base_link = "ws://localhost:%s/" % str(localhost_port)
	else:
		base_link = WEBSOCKET_LINK
	return base_link + slug
	
func check_password(input:String) -> bool:
	if input.length()==0:
		push_error("input invalid")
		return false
		
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"password":input
	}
	
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("users/checkpassword"))
	if response.has("error"):
		push_error("failed to receive signature by the server. ",response)
		return false
	
	return response["response_code"] == 200
	
