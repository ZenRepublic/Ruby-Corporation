extends Node
class_name SessionKeyCreator

@export var create_button:Button
@export var sol_top_up_amount:float
@export var duration_in_minutes:int

var session_program:Pubkey

signal on_choice_made(agreed:bool)

func _ready() -> void:
	create_button.pressed.connect(setup_session)
	
func setup_session_creator(program_key:Pubkey) -> void:
	session_program = program_key

func setup_session() -> void:
	var session_key:SessionKey = await SolanaService.wallet.start_session(session_program,sol_top_up_amount,duration_in_minutes)
#	the job is finished, session key created. move on
	on_choice_made.emit(session_key!=null)
	
	if session_key!=null:
		queue_free()
