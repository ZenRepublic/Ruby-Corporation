extends Node
class_name TensorCollectionEntry

@export var visual:TextureRect
@export var name_label:Label
@export var max_name_length:int
@export var select_button:Button

@export var allow_compressed:bool
@export var allow_inscriptions:bool
@export var allow_spl20:bool
@export var allow_core:bool

var data:Dictionary

signal on_selected(collection_data:Dictionary)

func setup_collection(collection_data:Dictionary) -> void:
	data = collection_data
	select_button.disabled=true
	
	if data.has("imageUri"):
		visual.texture = await SolanaService.file_loader.load_token_image(data["imageUri"],128,true)
	name_label.text = data["name"].substr(0,max_name_length)
	if len(name_label.text) < len(data["name"]):
		name_label.text += ".."
	
	if is_selectable(data):
		select_button.disabled=false
	else:
		select_button.text = "No Support"
		
	select_button.pressed.connect(handle_collection_select)
	
func handle_collection_select() -> void:
	on_selected.emit(data)

func is_selectable(data:Dictionary) -> bool:
	if !allow_compressed and data["compressed"] == true:
		return false
		
	if !allow_inscriptions and (data["inscription"] == true or data["inscriptionMetaplex"] == true):
		return false
		
	if !allow_spl20 and data["spl20"] == true:
		return false
		
	if !allow_core and data.has("tokenProgram") and data["tokenProgram"] == "MPL_CORE":
		return false
		
	return true
	
