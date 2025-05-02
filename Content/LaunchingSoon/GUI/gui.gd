extends Control
class_name GUI

@export var admin_panel:AdminPanel
@export var win_screen:Control
@export var lose_screen:Control

func _init() -> void:
	add_to_group("GUI")
	
func _ready() -> void:
	win_screen.visible=false
	lose_screen.visible=false
	
func handle_win_ui() -> void:
	win_screen.visible=true
	
func handle_lose_ui() -> void:
	lose_screen.visible=true
	
	
