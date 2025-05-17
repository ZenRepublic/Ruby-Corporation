extends Node
class_name PasswordLock

@export var password_input_system:DataInputSystem
@export var unlock_button:BaseButton
@export var error_label:Label
@export var error_show_duration:float = 2


var incorrect_input_entered:bool=false
var error_time_elapsed:float = 0

signal on_password_unlocked()

func _ready() -> void:
	if unlock_button!=null:
		unlock_button.pressed.connect(try_unlock)
		unlock_button.disabled=true
		password_input_system.on_fields_updated.connect(handle_input_update)
	
	error_label.visible=false
	
func _process(delta: float) -> void:
	if incorrect_input_entered:
		error_time_elapsed += delta
		if error_time_elapsed >= error_show_duration:
			error_label.visible=false
			incorrect_input_entered = false
		
func handle_input_update() -> void:
	unlock_button.disabled = !password_input_system.get_inputs_valid()
	
func try_unlock() -> void:
	var input_data:Dictionary = password_input_system.get_input_data()
	
	password_input_system.get_input_field("password").editable=false
	var success:bool = await RubianServer.check_password(input_data["password"])
	password_input_system.get_input_field("password").editable=true
		
	if success:
		on_password_unlocked.emit()
	else:
		password_input_system.reset_all_fields()
		incorrect_input_entered = true
		error_time_elapsed = 0
		error_label.visible=true
