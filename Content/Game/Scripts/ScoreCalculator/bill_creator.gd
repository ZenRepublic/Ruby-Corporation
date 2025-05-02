extends Control
class_name BillCreator

@export var bill_slot_scn:PackedScene
@export var reward_claimer:CampaignRewardClaimer

@onready var bill_container:VBoxContainer = $BillContainer
@onready var spacer:HBoxContainer = $Spacer

@onready var claim_container:Control = $ClaimContainer
@onready var final_price_label:NumberLabel = $ClaimContainer/FinalPrice
@onready var final_price_visual:TextureRect = $ClaimContainer/Visual
@onready var max_label:Control = $ClaimContainer/MaxLabel
@onready var action_button:Button = $ClaimContainer/ActionButton
@onready var audio_player:AudioStreamPlayer = $AudioStreamPlayer
var bill_slots:Array[BillSlot]

var final_score:float

signal on_reward_claimed(amount_claimed)

func _ready() -> void:
	reward_claimer.on_reward_claimed.connect(handle_reward_claim)
	SolanaService.transaction_manager.on_tx_cancelled.connect(handle_tx_cancel)
	
	spacer.visible=false
	action_button.visible=false
	claim_container.visible = false
	max_label.visible = false
	
func generate_bill(collected_items:Dictionary,game_mode:GameManager.GameMode) -> void:
	setup_action_button(game_mode)
	
	var token_unit_price:float = 1.0
	var token_texture:Texture2D = null
	
	if game_mode == GameManager.GameMode.MINING:
		token_unit_price = reward_claimer.get_token_unit_price(false)
		token_texture = reward_claimer.get_reward_token_texture()
		
	if token_texture != null:
		final_price_visual.texture = token_texture
		
	for key in collected_items.keys():
		var slot_instance:BillSlot = bill_slot_scn.instantiate()
		bill_container.add_child(slot_instance)
		bill_slots.append(slot_instance)
		await slot_instance.setup(self,collected_items[key],token_unit_price,token_texture)	
	
	await get_tree().create_timer(0.3).timeout
	spacer.visible = true
	var spacer_line:Control = spacer.get_child(1)
	spacer_line.size_flags_stretch_ratio=0
	var tween:Tween = get_tree().create_tween()
	tween.tween_property(spacer_line,"size_flags_stretch_ratio",1.0,0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	final_price_label.set_value(0)
	claim_container.visible = true
	
	var max_allowed_reward:float = reward_claimer.score_to_max_reward
	if game_mode == GameManager.GameMode.MINING:
		max_allowed_reward = reward_claimer.get_max_reward()
		
	for slot in bill_slots:
		final_score += slot.get_total_value()
	final_score = clamp(final_score,0,max_allowed_reward)
		
	var final_claim_display_amount:float=0
	for slot in bill_slots:
		var transfer_tick_count:int = 5
		var transfer_rate:float = slot.total_value/transfer_tick_count
		var slot_value:float = slot.get_total_value()
		for i in range(transfer_tick_count):
			slot_value -= transfer_rate
			slot_value = clamp(slot_value,0,INF)
			slot.token_value_label.set_value(slot_value)
			final_claim_display_amount += transfer_rate
			final_claim_display_amount = clamp(final_claim_display_amount,0,max_allowed_reward)
			final_price_label.set_value(final_claim_display_amount)
			play_increment_sound(lerp(1.0,1.4,final_claim_display_amount/final_score))
			await get_tree().create_timer(0.07).timeout
			
	if final_score == max_allowed_reward:
		max_label.visible = true
		
	await get_tree().create_timer(0.3).timeout
	action_button.visible=true
	
func play_increment_sound(pitch:float) -> void:
	if audio_player.stream == null:
		return
		
	if pitch == INF or pitch == -INF:
		print("Can't play a sound of %s pitch" % pitch)
		return
	
	audio_player.pitch_scale = snapped(pitch,0.01)
	audio_player.play()
	
func setup_action_button(game_mode:GameManager.GameMode) -> void:
	match game_mode:
		GameManager.GameMode.TRAINING:
			action_button.text = "Return"
			action_button.pressed.connect(return_to_menu)
		GameManager.GameMode.REPLAYING:
			action_button.text = "Replay"
			action_button.pressed.connect(replay_game)
		GameManager.GameMode.MINING:
			action_button.text = "Claim"
			action_button.pressed.connect(try_claim_reward)
	
		
func return_to_menu() -> void:
	MusicManager.play_sound("ButtonJuicy")
	action_button.disabled = true
	var game_manager:GameManager = get_tree().get_first_node_in_group("GameManager")
	game_manager.return_to_menu()
	
func replay_game() -> void:
	MusicManager.play_sound("ButtonJuicy")
	action_button.disabled = true
	SceneManager.reload_scene(true,-1,{})
	
func try_claim_reward() -> void:
	MusicManager.play_sound("ButtonJuicy")
	action_button.disabled = true
	await reward_claimer.claim_reward(final_score)
		
func handle_reward_claim(success:bool) -> void:
	if success:
		on_reward_claimed.emit(final_score)
		#var game_manager:GameManager = get_tree().get_first_node_in_group("GameManager")
		#game_manager.return_to_menu()
	else:
		action_button.disabled = false
		
func handle_tx_cancel() -> void:
	action_button.disabled = false
	
	
