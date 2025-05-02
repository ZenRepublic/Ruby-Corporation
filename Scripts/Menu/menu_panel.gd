extends Node

@export var screen_manager:ScreenManager
@export var user_address_label:Label
@export var version_label:Label

@export var settings_button:BaseButton
@export var settings_panel:Control
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	version_label.text = str(ProjectSettings.get_setting("application/config/version"))
	
	if SolanaService.wallet.get_pubkey()!=null:
		user_address_label.text = SolanaService.wallet.get_shorthand_address()
	
	settings_button.pressed.connect(show_settings)
		

func show_settings() -> void:
	settings_panel.visible=true
