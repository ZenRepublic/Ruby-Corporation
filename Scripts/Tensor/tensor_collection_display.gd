extends Node
class_name TensorCollectionDisplay

@export var tensor_api:TensorAPI
@export var show_limit:int = 20
@export var container:Container
@export var no_asset_overlay:Control
@export var display_entry_scn:PackedScene
@export var search_bar:InputField
@export var search_button:Button

@export var find_onchain_id:bool=true
@export var close_on_select:bool
@export var destroy_on_close:bool

var entries:Array[TensorCollectionEntry]

signal on_display_updated
signal on_collection_selected(collection_data:Dictionary)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	on_display_updated.connect(handle_display_update)
	
	if search_bar!=null:
		search_bar.on_field_updated.connect(search_collections)
			
func search_collections(query:String) -> void:
	clear_display()
	if query.length() == 0:
		return
	
	var collections:Dictionary = await tensor_api.search_collections(query,show_limit)
	if collections.size() == 0 or !collections.has("collections"):
		return
		
	for collection in collections["collections"]:
		var entry_instance:TensorCollectionEntry = display_entry_scn.instantiate() as TensorCollectionEntry
		container.add_child(entry_instance)
		
		entry_instance.on_selected.connect(handle_displayable_selection)
		entry_instance.setup_collection(collection)
		
		entries.append(entry_instance)
		on_display_updated.emit()

	
func handle_displayable_selection(selected_collection_data:Dictionary) -> void:
	if find_onchain_id:
		var onchain_id = await get_onchain_id(selected_collection_data["collId"])
		selected_collection_data["onchainId"] = onchain_id
			
	on_collection_selected.emit(selected_collection_data)
	if close_on_select:
		close()
	
		
func clear_display() -> void:
	for entry in entries:
		entry.queue_free()
	
	entries.clear()
	on_display_updated.emit()
	
func handle_display_update() -> void:
	if no_asset_overlay!=null:
		no_asset_overlay.visible = (container.get_children().size()==0)
		container.visible = !no_asset_overlay.visible
	
func close() -> void:
	if search_bar!=null:
		search_bar.text = ""
		search_collections("")
		
	self.visible = false
	if destroy_on_close:
		queue_free()
		
func get_onchain_id(offchain_id:String):
	var whitelist_info:Array = await tensor_api.get_whitelist_info([offchain_id])
	var has_collection_id:bool
	var collection_id_index:int=-1
	for condition in whitelist_info[0]["conditions"]:
		collection_id_index+=1
		if condition["mode"] == "VOC":
			has_collection_id=true
			break
			
	if has_collection_id:
		return whitelist_info[0]["conditions"][collection_id_index]["value"]
	else:
		return null
