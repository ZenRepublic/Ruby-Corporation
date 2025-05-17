extends Node
class_name DatabaseManager

func setup_database_manager() -> void:
	pass

func register_user(user:Pubkey) -> void:
	if user == null:
		push_error("User not found")
		return
		
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"walletAddress":user.to_string()
	}
	var _response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("users/register"))

func submit_visual(link:String) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"walletAddress":SolanaService.wallet.get_pubkey().to_string(),
		"link":link
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("users/submitvisual"))
	return response
	
func get_submissions(user:Pubkey=null) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	var url:String = RubianServer.get_request_link("users/getsubmissions")
	if user != null:
		url += "?address=" + user.to_string()
		
	var response:Dictionary = await HttpRequestHandler.send_get_request(url,true,headers)
	return response
	
func reject_submission(user:Pubkey,submission:String) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"address":user.to_string(),
		"submission":submission
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("users/removesubmission"))
	return response
