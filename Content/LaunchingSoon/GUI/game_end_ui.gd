extends Node
class_name GameEndUI

@export var score_label:NumberLabel
@export var token_visual:TextureRect
@export var action_button:Button

var earn_amount:float

signal on_reward_claimed(claimed)

func _ready() -> void:
	ClubhouseProgram.claimer.on_reward_claimed.connect(handle_reward_claim)
	SolanaService.transaction_manager.on_tx_cancelled.connect(handle_tx_cancel)
	
func setup_ui(earn_amount:float,free_play_mode:bool) -> void:
	self.earn_amount = earn_amount
	action_button.visible=false
	
	var token_tex:Texture2D = ClubhouseProgram.claimer.get_reward_token_texture()
	if token_tex!=null:
		token_visual.texture = token_tex
	
	var increment_value:float=0
	
	if free_play_mode:
		action_button.text = "Return"
		action_button.pressed.connect(return_to_menu)
		increment_value = LaunchSettings.BASE_PLACEMENT_SCORE*1.5
	else:
		action_button.text = "Claim"
		action_button.pressed.connect(try_claim_reward)
		increment_value = ClubhouseProgram.claimer.get_token_unit_price(false)*1.5
		
	await score_label.lerp_to_value(earn_amount,increment_value)
		
	action_button.visible=true	
		
func return_to_menu() -> void:
	MusicManager.play_sound("ButtonJuicy")
	action_button.disabled = true
	var launch_controller:LaunchController = get_tree().get_first_node_in_group("LaunchController")
	launch_controller.return_to_menu()

func try_claim_reward() -> void:
	MusicManager.play_sound("ButtonJuicy")
	action_button.disabled = true
	await ClubhouseProgram.claimer.claim_reward(earn_amount)


func handle_reward_claim(success:bool) -> void:
	if success:
		on_reward_claimed.emit()
	else:
		action_button.disabled = false
		
func handle_tx_cancel() -> void:
	action_button.disabled = false
