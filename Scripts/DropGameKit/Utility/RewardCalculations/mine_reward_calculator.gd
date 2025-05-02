@tool
extends Node
class_name MineRewardCalculator

@export_file(".json") var holder_list_path:String
@export var token_allocation_per_nft:float
@export var adjust_allocation_by_health:bool=true
@export var avg_reward_percentage_per_game:float = 0.6
@export var initial_energy:int
@export var recharge_rate_in_minutes:int
@export var campaign_length_in_days:int
@export_range(0.0,0.1,0.0001) var claim_fee:float
@export var expected_activity:float = 0.1

@export var calculate: bool:
	set(value):
		calculate_rewards()
		
func get_hashlist(path:String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var finish = JSON.parse_string(content)
	return finish

func calculate_rewards() -> void:
	var hashlist:Array = get_hashlist(holder_list_path)
	
	var holdings:Array
	for holder in hashlist:
		holdings.append(holder["count"])
		
	var collection_size:int=0
	for holder in holdings:
		collection_size += holder
	
	print("Collection Size: ",collection_size)
	print("Total Unique Holders: ",holdings.size())
	
	var collection_score:float = calculate_collection_score(holdings)
	var final_score:int = ceili(collection_score)
	print("Holder Distribution Score: ",final_score)
	
	var expected_amount_of_players = floori(holdings.size() * expected_activity) * calculate_median(holdings)
	print("Expected amount of NFT Players: ",expected_amount_of_players)
	
	var max_attempts:int = calculate_total_possible_attempts()
	print("Max Attempts per Player: ",max_attempts)
	
	var total_player_allocation = token_allocation_per_nft
	if adjust_allocation_by_health:
		total_player_allocation = total_player_allocation * (final_score/10.0)
		var holder_average:int = calculate_average(holdings,collection_size)
		var normalized_holder_average = max(1.0 - (holder_average-1)/max_allowed_holder_average,0)
		total_player_allocation = total_player_allocation * normalized_holder_average
		
	print("Max Allocation Per Player: %s, Average Earn Amount: %s" % [total_player_allocation,total_player_allocation*avg_reward_percentage_per_game])
	
	var max_reward_per_game:float = total_player_allocation/max_attempts
	print("Max Reward Per Attempt: ",max_reward_per_game)
	
	print("Mine Treasury Size: ",total_player_allocation*expected_amount_of_players)
	
	var cost_per_player:float = max_attempts * claim_fee
	print("Fee Cost Per Player: ",cost_per_player)
	
	var expected_fees_earned:float = cost_per_player * expected_amount_of_players
	print("EXPECTED FEES EARNED: ",expected_fees_earned)

	
	
	
func calculate_total_possible_attempts() -> int:
	var total_attempts:int = initial_energy
	if recharge_rate_in_minutes == 0:
		return total_attempts
		
	var campaign_length_in_minutes:int = campaign_length_in_days * 24 * 60
	total_attempts += floori(campaign_length_in_minutes/recharge_rate_in_minutes)
	return total_attempts
	
	
# Weights (adjust to preference)
var weight_average = 0.15
var weight_median = 0.15
var weight_std_dev = 0.25
var weight_top_10 = 0.20
var weight_gini = 0.25

var max_allowed_holder_average = 5.0
var max_allowed_holder_median = 3.0
var max_allowed_standard_deviation = 15.0
# 6. Calculate the score based on the metrics, outputting a score from 0 to 10
func calculate_collection_score(holdings: Array) -> float:
	var total_size:int=0
	for holder in holdings:
		total_size += holder
	# Calculate metrics
	var average = calculate_average(holdings,total_size)
	var median = calculate_median(holdings)
	var std_dev = calculate_standard_deviation(holdings, average)
	var top_10_concentration = calculate_top_10_percent_concentration(holdings,total_size)
	var gini = calculate_gini_coefficient(holdings)
	
	# Normalized metrics (each metric is scaled from 0 to 1)
#	for average and median take one off because theres no penalty for having 1 average and median
	var normalized_average = max(1.0 - (average-1)/max_allowed_holder_average,0)
	#print(normalized_average)
	var normalized_median = max(1.0 - (median-1)/max_allowed_holder_median,0)
	#print(normalized_median)
	var normalized_std_dev = max(1.0 - std_dev/max_allowed_standard_deviation,0)
	#print(normalized_std_dev)
	var normalized_top_10 = 1.0 - top_10_concentration
	#print(normalized_top_10)
	var normalized_gini = 1.0 - gini
	#print(normalized_gini)
	
	# Final score calculation, scaled from 0 to 10
	var score = (weight_average * normalized_average + weight_median * normalized_median + 
				 weight_std_dev * normalized_std_dev + weight_top_10 * normalized_top_10 +
				 weight_gini * normalized_gini) * 10
	
	return score
	
	
# 1. Calculate the average NFTs per holder
func calculate_average(holdings: Array, total_size:int) -> float:
	return roundi(float(total_size) / holdings.size())
	
	
func calculate_median(holdings: Array) -> float:
	var sorted_holdings:Array = holdings.duplicate()
	sorted_holdings.sort()
	
	var mid = sorted_holdings.size() / 2
	return sorted_holdings[mid] if sorted_holdings.size() % 2 != 0 else (sorted_holdings[mid - 1] + sorted_holdings[mid]) / 2.0

# 3. Calculate the standard deviation of NFTs held
func calculate_standard_deviation(holdings: Array, average: float) -> float:
	var variance = 0.0
	for count in holdings:
		variance += pow(count - average, 2)
	return sqrt(variance / holdings.size())
	
# 4. Calculate the top 10% holder concentration
func calculate_top_10_percent_concentration(holdings: Array, total_size:int) -> float:
	var sorted_holdings:Array = holdings.duplicate()
	sorted_holdings.sort()
	sorted_holdings = sorted_holdings.slice(-int(holdings.size() * 0.1))
	var sorted_holder_amount:int=0
	for holder in sorted_holdings:
		sorted_holder_amount += holder
	return sorted_holder_amount / float(total_size)

# 5. Calculate the Gini coefficient
func calculate_gini_coefficient(holdings: Array) -> float:
	var sorted_holdings = holdings.duplicate()
	sorted_holdings.sort()
	
	var sorted_holder_amount:int=0
	for holder in sorted_holdings:
		sorted_holder_amount += holder
	
	var n = sorted_holdings.size()
	var total = sorted_holder_amount
	var gini_sum = 0.0
	for i in range(n):
		gini_sum += (2 * (i + 1) - n - 1) * sorted_holdings[i]
	return gini_sum / (n * total) if total != 0 else 0.0
