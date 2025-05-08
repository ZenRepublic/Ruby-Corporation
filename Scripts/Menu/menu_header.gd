extends Node

@export var user_address_label:Label
@export var login_button:BaseButton

@export var token_vault_scn:PackedScene
@export var vault_button:BaseButton

@export var settings_screen:Control
@export var settings_button:BaseButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vault_button.visible=false
	settings_screen.visible=false
	
	SolanaService.wallet.on_login_success.connect(handle_login)
	
	login_button.pressed.connect(try_login)
	vault_button.pressed.connect(open_player_vault)
	settings_button.pressed.connect(show_settings)
	
func try_login() -> void:
	SolanaService.wallet.try_login()
	
func handle_login() -> void:
	login_button.visible=false
	vault_button.visible=true
	
	if SolanaService.wallet.get_pubkey()!=null:
		user_address_label.text = SolanaService.wallet.get_shorthand_address()
		
func open_player_vault() -> void:
	var token_vault_instance:StakeTokenVault = token_vault_scn.instantiate()
	get_tree().root.add_child(token_vault_instance)
	
func show_settings() -> void:
	settings_screen.visible=true
