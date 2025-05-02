extends Node
class_name SecretCodeInput

@export var available_codes:Array[String]
@export var letter_remove_rate:float = 0.4
@export var is_active:bool=true
@export var disable_on_solved:bool=true

var char_stream:String
var time_to_remove:float=0

signal on_code_entered(code:String)

func _ready() -> void:
	time_to_remove = letter_remove_rate

func _process(delta: float) -> void:
	if !is_active:
		return
	
	#if char_stream.length() > 0:
	var code_found:bool=false
	for code in available_codes:
		if char_stream.contains(code.to_upper()):
			on_code_entered.emit(code)
			code_found=true
			break
	
	if code_found:
		char_stream=""
		if disable_on_solved:
			is_active = false
	
	if char_stream.length() > 0:
		time_to_remove -= delta
		if time_to_remove <= 0:
			char_stream = char_stream.erase(0,1)
			time_to_remove = letter_remove_rate
	

func _unhandled_input(event: InputEvent) -> void:
	# Check if the event is a key press
	if !is_active:
		return
		
	if event is InputEventKey and event.is_pressed():
		var key = event as InputEventKey
		var key_char:String = key.as_text_keycode()
		
		#skip escape,shift,alt, etc		
		if key_char.length()>1:
			return
			
		char_stream += key_char
#		reset timer on each letter added
		time_to_remove = letter_remove_rate
