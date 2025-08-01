extends Node
class_name RPCManager

enum PriorityFeeLevel {min,low,medium,high,veryHigh}

@export var priority_fee_level:PriorityFeeLevel
@export var use_recommended_fee:bool=true
		
func setup_rpc_manager() -> void:
	SolanaService.mainnet_rpc = RubianServer.get_request_link("mainnet-rpc")
	SolanaService.devnet_rpc = RubianServer.get_request_link("devnet-rpc")
	SolanaService.set_rpc_cluster(SolanaService.rpc_cluster)
	
func get_cluster_string() -> String:
	var cluster_name:String = SolanaService.RpcCluster.keys()[SolanaService.rpc_cluster]
	return cluster_name.to_lower()
	
func calculate_fee(tx:Transaction) -> int:
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"transaction":SolanaUtils.bs58_encode(tx.serialize()),
		"useRecommended":use_recommended_fee,
		"priorityFeeLevel":PriorityFeeLevel.keys()[priority_fee_level],
		"network": get_cluster_string()
	}
	var response:Dictionary = await HttpRequestHandler.send_post_request(JSON.stringify(body),headers,RubianServer.get_request_link("calculatefee"),)
	if response.has("error"):
		return 0
	else:
		return response["body"]["estimated_fee"]
