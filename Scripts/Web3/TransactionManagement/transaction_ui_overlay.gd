extends Node

@export var time_to_close = 2.5
@export var auto_close_success:bool=true
@export var auto_close_fail:bool=true

@export var error_text_label:Label

@onready var screen_manager = $ScreenManager

var curr_tx_data:TransactionData
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SolanaService.transaction_manager.on_tx_create_start.connect(enable_tx_screen)
	SolanaService.transaction_manager.on_tx_finish.connect(process_tx_finish)
	SolanaService.transaction_manager.on_tx_cancelled.connect(process_tx_cancel)
	
	
func enable_tx_screen() -> void:
	screen_manager.switch_active_panel(0)
	
func process_tx_finish(tx_data:TransactionData) -> void:
	curr_tx_data = tx_data
	
	if tx_data.is_successful():
		screen_manager.switch_active_panel(1)
		if auto_close_success:
			await get_tree().create_timer(time_to_close).timeout
			#there may be a new transaction brewing, so only close if still in this screen
			if screen_manager.curr_active_panel == screen_manager.screens[1]:
				screen_manager.close_active_panel()
	else:
		screen_manager.switch_active_panel(2)
		if error_text_label!=null:
			error_text_label.text = tx_data.get_error_message(false)
		if auto_close_fail:
			await get_tree().create_timer(time_to_close).timeout
			screen_manager.close_active_panel() 
			
func process_tx_cancel() -> void:
	screen_manager.close_active_panel()
	
func copy_error_logs() -> void:
	if curr_tx_data == null:
		return
		
	DisplayServer.clipboard_set(curr_tx_data.get_error_message())
	
func manual_overlay_close() -> void:
	screen_manager.close_active_panel() 
