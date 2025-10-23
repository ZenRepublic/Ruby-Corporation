extends Node

@export var jupiter_api:JupiterAPI
@export var token_ca_to_sell:String
@export var token_ca_to_buy:String

@export var option_buttons:Array[Button]
@export var price_options:Array[float]
@export var option_group:ButtonGroup

@export var buy_button:ButtonLock
var original_buy_text:String

var selected_amount:float=0

func _ready() -> void:
	buy_button.disabled=true
	original_buy_text = buy_button.text
	buy_button.pressed.connect(try_buy_token)
	
	option_group.pressed.connect(handle_option_select)
	
	for i in range(option_buttons.size()):
		option_buttons[i].button_group = option_group
		option_buttons[i].text = "%s SOL" % price_options[i]

func handle_option_select(selected_button:BaseButton) -> void:
	var button_id:int = option_buttons.find(selected_button,0)
	selected_amount = price_options[button_id]
	
	await buy_button.try_unlock()
	
func try_buy_token() -> void:
	buy_button.disabled=true
	buy_button.text = "LOADING..."
	
	var sell_token:Pubkey =Pubkey.new_from_string(token_ca_to_sell)
	var buy_token:Pubkey =Pubkey.new_from_string(token_ca_to_buy)
	
	var swap_quote:Dictionary = await jupiter_api.get_swap_quote(sell_token,buy_token,selected_amount,0.5)
	if swap_quote == {}:
		handle_buy_finish(false)
		return
		
	var tx_data:TransactionData = await jupiter_api.swap_token(SolanaService.wallet.get_pubkey(),swap_quote)
	handle_buy_finish(tx_data.is_successful())
		
func handle_buy_finish(success:float) -> void:
	if success:
		buy_button.text = original_buy_text
		for button in option_buttons:
			button.button_pressed=false
	else:
		await buy_button.try_unlock()

	
