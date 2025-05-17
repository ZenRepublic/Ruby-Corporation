extends Node
class_name DataUploader

func setup_data_uploader() -> void:
	pass
		
func get_upload_price(file_to_upload) -> Dictionary:
	var serialized_file:PackedByteArray
	
	if file_to_upload is String:
		serialized_file = file_to_upload.to_utf8_buffer()
	elif file_to_upload is Image:
		serialized_file = file_to_upload.save_png_to_buffer()  # Encode to PNG
		
	var file_byte_size:int = serialized_file.size()
	
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"fileSize":file_byte_size
	}
	
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("turbo/getprice"))
	return response
	
func get_upload_details() -> Dictionary:
	var response:Dictionary = await HttpRequestHandler.send_get_request(RubianServer.get_request_link("turbo/getdetails"),true)
	return response
	
	
func upload_uri(data:Dictionary) -> Dictionary:
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"uriData": data
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("turbo/uploaduri"))
	return response
	
func upload_image(image:Image, uri:Dictionary) -> Dictionary:
	var upload_data:Dictionary = await get_upload_details()
	print(upload_data)
	var payment_receiver:Pubkey = Pubkey.new_from_string(upload_data["body"]["receiverAddress"])
	var upload_price:float = upload_data["body"]["uploadFeeLamports"] / pow(10,9) 
	var tx_data:TransactionData = await SolanaService.transaction_manager.transfer_sol(payment_receiver,upload_price)
	
	var image_buffer:PackedByteArray = image.save_png_to_buffer() 
	var image_base64:String = Marshalls.raw_to_base64(image_buffer)
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"txSignature": tx_data.get_tx_id(),
		"imageBuffer": image_base64,
		"uriData": uri
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("turbo/uploadimage"))
	return response
