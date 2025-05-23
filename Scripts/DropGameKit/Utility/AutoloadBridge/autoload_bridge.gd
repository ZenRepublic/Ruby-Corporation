extends Node

func _ready():
	get_tree().root.set_meta("autoload_bridge", self)
	
func get_scene_manager():
	return get_node_or_null("/root/SceneManager")
	
func get_clubhouse_program():
	return get_node_or_null("/root/ClubhouseProgram")
	
func get_solana_service():
	return get_node_or_null("/root/SolanaService")
