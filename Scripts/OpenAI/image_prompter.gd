extends Node
class_name ImagePrompter

@export var image_size:int = 256
@export var amount_to_generate:int = 1
@export var temperature:float = 0.5
@export var model:String
var end_point:String = "https://api.openai.com/v1/images/generations"

var http_request_image:HTTPRequest

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func generate_image(prompt:String) -> Texture2D:
	var body = JSON.stringify({
		"prompt": prompt,
		"n": amount_to_generate,
		"quality": "standard",
		"size" : "%sx%s" % [image_size,image_size],
		"model": model
	})
	
	var response:Dictionary = await HttpRequestHandler.send_post_request(body, OpenAI.headers, end_point)
	var image_url = response["body"]["data"][0]["url"]
	var img_response:Dictionary = await HttpRequestHandler.send_get_request(image_url,false)
	var img_tex:Texture2D = parse_image(img_response["body"],image_size)
	
	return img_tex
	
func parse_image(buffer,size:int) -> Texture2D:
	var image = Image.new()
	var img_load_request = image.load_png_from_buffer(buffer)
	if img_load_request != OK:
		print("Failed to parse the prompted image")
		return null
		
	image.resize(size,size)
	return ImageTexture.create_from_image(image)
