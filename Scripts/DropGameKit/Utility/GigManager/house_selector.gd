extends Node
class_name HouseSelector

@export var house_manager_scn:PackedScene
@export var manage_button:AddressButtonLock

func _ready() -> void:
	manage_button.pressed.connect(pop_house_manager)
	var program_admins:Array[Pubkey] = await ClubhouseProgram.utils.get_program_admin_list()
	manage_button.set_address_list(program_admins)
	
func pop_house_manager() -> void:
	var house_manager_instance:HouseAdminSystem = house_manager_scn.instantiate()
	get_tree().root.add_child(house_manager_instance)
