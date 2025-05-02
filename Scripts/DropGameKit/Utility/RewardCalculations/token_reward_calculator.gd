@tool
extends Node
class_name TokenRewardCalculator

@export var holder_count:int
@export_range(0.0,0.1,0.0001) var token_price:float
@export var avg_allocation_mined:float = 0.6
@export var dollar_price_per_attempt:float = 20.0
@export var expected_participation:float=0.05
@export var participation_activeness:float = 0.5
@export var desired_player_allocation:float = 5000
@export var minimum_attempts_to_goal:int=20
@export_range(0.0,0.1,0.0001) var claim_fee:float = 0.0005

@export var calculate: bool:
	set(value):
		calculate_rewards()
		calculate=false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func calculate_rewards() -> void:
	var player_count:int = roundi(holder_count * expected_participation)
	print("Expected Player count: ",player_count)
	var total_allocation:int = player_count * desired_player_allocation
	print("Total Allocation: ",total_allocation)
	
	var allocation_per_run:int = roundi(desired_player_allocation/minimum_attempts_to_goal)
	allocation_per_run =  allocation_per_run / avg_allocation_mined
	print("Max Allocation per attempt: ",allocation_per_run)
	
	var token_entrance_fee:float = dollar_price_per_attempt / token_price
	print("Token price per attempt: ", token_entrance_fee)
	
	var expected_times_played:float = player_count * (minimum_attempts_to_goal * participation_activeness)
	var fees_earned:float = claim_fee * expected_times_played 
	print("Expected fees earned: ",fees_earned)
	
	var value_locked:float = (expected_times_played * token_entrance_fee) * token_price
	print("Expected value locked: ", value_locked)
