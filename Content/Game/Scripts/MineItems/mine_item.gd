extends Node2D
class_name MineItem

enum ItemType {TREASURE, UTILITY, OBSTACLE}

@onready var visual:Sprite2D = $Sprite
@onready var audio_player:SFXManager = $AudioStreamPlayer

@export var type:ItemType
@export var focus_zoom_strength:float
var occupied_tiles:Array[MineTile]
#
#@onready var audio_player:SFXManager = $AudioStreamPlayer

signal on_uncover_started(item:MineItem)
signal on_uncover_finished(item:MineItem)

# Called when the node enters the scene tree for the first time.
func _ready():
	#tree_exited.connect(conclude_uncover)
	pass # Replace with function body.

	
func set_occupied_tiles(tiles_to_occupy:Array[MineTile]) -> void:
	occupied_tiles = tiles_to_occupy.duplicate()
	
	for tile in occupied_tiles:
		tile.occupied_by=self

func try_uncover(_destroyed_tile:MineTile) -> void:
	var uncovered:bool = true
	for tile in occupied_tiles:
		if !tile.destroyed:
			uncovered=false
	if !uncovered:
		return
		
	for tile in occupied_tiles:
		tile.occupied_by = null
		
	var game_manager:GameManager = get_tree().get_first_node_in_group("GameManager")
#	when it's time for this item, uncover function will be called from gamemanager
	game_manager.add_item_to_queue(self)
	
		
func uncover() -> void:
	on_uncover_started.emit(self)
	pass
	
func conclude_uncover() -> void:
	on_uncover_finished.emit(self)
	
func destroy() -> void:
	if audio_player.playing:
		await audio_player.finished
	queue_free()
	pass
