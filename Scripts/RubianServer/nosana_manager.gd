extends Node
class_name NosanaManager

var socket:WebSocketPeer

var client_id:String

var active_prompt_data:Dictionary
var output_images:Dictionary

signal on_generate_failed()
signal on_generation_finished(generated_images:Dictionary)
signal on_socket_update(message_data:Dictionary)
signal on_socked_closed()

func setup_nosana_manager() -> void:
	pass

func _process(delta):
	if socket == null:
		return
		
	socket.poll()  # Continuously poll the WebSocket connection

	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			# Check for incoming packets
			while socket.get_available_packet_count() > 0:
				var msg:PackedByteArray = socket.get_packet()
				handle_websocket_message(msg)
		WebSocketPeer.STATE_CLOSING:
			# Keep polling for proper closure
			pass
		WebSocketPeer.STATE_CLOSED:
			print("WebSocket closed")
			active_prompt_data.clear()
			on_socked_closed.emit()
			socket = null
			
func handle_websocket_message(byte_array:PackedByteArray):
	var json = JSON.new()
	json.parse(byte_array.get_string_from_utf8())
	var msg_body:Dictionary = json.get_data()
	on_socket_update.emit(msg_body)
	
	if !msg_body.has("type") or !msg_body.has("data"):
		print("Missing websocket body type!")
		return
		
	var data = msg_body["data"]
	
	if msg_body["type"] == "executed" and data.has("output"):
		for image_info in data["output"]["images"]:
			output_images[data["node"]] = image_info
	
	elif msg_body["type"] == "execution_success":
		if data["prompt_id"] == active_prompt_data["prompt_id"]:
			print("Processing completed for prompt_id: ", active_prompt_data["prompt_id"])
			on_generation_finished.emit(output_images)
			socket.close()
	
	
func load_images() -> void:
	for key in output_images.keys():
		var image:Image = await fetch_generated_image(output_images[key])
		output_images[key] = image
	on_generation_finished.emit(output_images)

func queue_prompt(client_id:String,workflow:Dictionary):
	var headers:Array = ["Content-type: application/json"]
	
	var body:Dictionary = {
		"prompt":workflow,
		"client_id":client_id
	}
	
 # Create regex to match .0 not followed by more digits
	var regex = RegEx.new()
	regex.compile("\\.0(?!\\d)")  # Matches ".0" unless followed by a digit
	var stringified_body:String = regex.sub(JSON.stringify(body), "", true)
	var response:Dictionary = await HttpRequestHandler.send_post_request(stringified_body,headers,RubianServer.get_request_link("nosana/generateimage"))
	if response.has("error"):
		print("Image generation failed: ", response)
		on_generate_failed.emit()
		return
		
	active_prompt_data = response["body"]
	output_images = {}
	
	socket = WebSocketPeer.new()
	var error = socket.connect_to_url("%s/ws?clientId=%s" % [RubianServer.get_websocket_link("nosana/initwebsocket"), client_id])
	if error != OK:
		print("Image generation failed: ", error)
		on_generate_failed.emit()
		return

	
func fetch_generated_image(image_info:Dictionary) -> Image:
	# URL encode the data dictionary into a query string
	var url_values:String = ""
	for key in image_info.keys():
		#if image_info[key] == "":
			#continue
		url_values += key + "=" + image_info[key] + "&"
	url_values = url_values.trim_suffix("&")  # Remove trailing "&"
	
	var headers:Array = ["Content-type: application/json"]
	
	var body:Dictionary = {
		"slug":url_values,
	}
	
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("nosana/viewimage"),false)
	if response.has("error"):
		print("FAILED TO LOAD GENERATED IMAGE: ",response)
		return null
		
	print("IMAGE RECEIVED")
	var image = Image.new()
	image.load_png_from_buffer(response["body"])
	#image.save_png("res://imageai.png")
	return image


func has_png_signature(raw_image_data:PackedByteArray)->bool:
	var marker:PackedByteArray = PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10])
	return raw_image_data.slice(0,8) == marker
	
func is_alive() -> bool:
	var headers:Array = ["Content-type: application/json"]
	var response:Dictionary = await HttpRequestHandler.send_get_request(RubianServer.get_request_link("nosana/alivecheck"),true,headers)
	if response.has("error"):
		return false
	return response["body"]["isAlive"]
	
func load_workflow(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Unable to open file: ", path)
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json:JSON = JSON.new()
	json.parse(json_string)
	return json.data
