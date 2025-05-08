extends Node
class_name HouseAdminSystem

@export var screen_manager:ScreenManager
@export var house_selector:AccountDisplaySystem
@export var house_creator:HouseCreator
@export var house_manager:HouseManager


func _ready() -> void:
	house_selector.on_account_selected.connect(load_house)
	house_creator.on_house_created.connect(handle_house_create)
	house_manager.on_house_edited.connect(handle_house_update)
	house_manager.on_house_closed.connect(handle_house_close)
	
	house_selector.set_list(ClubhouseProgram.get_program(),"House",[],5,true)
	
		
func handle_house_create() -> void:
	house_selector.refresh_account_list()
	
func handle_house_update() -> void:
	house_selector.refresh_account_list()
	
func handle_house_close() -> void:
	house_selector.refresh_account_list()
	screen_manager.switch_active_panel(1)
	
func go_create_new_house() -> void:
	screen_manager.switch_active_panel(3)
	
	
func load_house(selected_entry:AccountDisplayEntry) -> void:
	screen_manager.switch_active_panel(0)
	await house_manager.set_house_data(selected_entry.account_id,selected_entry.data)
	screen_manager.switch_active_panel(2)

func close() -> void:
	queue_free()
