extends Node3D

@onready var panel_positions: Node3D = $Fueselage/Rocket_Body/PanelPositions
@onready var panels: Node3D = $Fueselage/Rocket_Body/Panels
@export var max_stickers : int = 5

var amount_of_positions : int = 0
var amount_of_stickers : int = 0
var chosen_panel_positions : Array
var chosen_panel_stickers : Array
func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var total_positions = panel_positions.get_child_count()
	var total_stickers = panels.get_child_count()

	# Ensure at least 2, and at most the number of available children
	amount_of_positions = rng.randi_range(2, total_positions)
	amount_of_stickers = rng.randi_range(2, min(max_stickers, total_stickers, amount_of_positions))

	var position_indices = range(total_positions)
	var sticker_indices = range(total_stickers)

	position_indices.shuffle()
	sticker_indices.shuffle()

	chosen_panel_positions = position_indices.slice(0, amount_of_positions)
	chosen_panel_stickers = sticker_indices.slice(0, amount_of_stickers)

	for i in range(min(chosen_panel_positions.size(), chosen_panel_stickers.size())):
		var position_node := panel_positions.get_child(chosen_panel_positions[i])
		var sticker_node := panels.get_child(chosen_panel_stickers[i])

		sticker_node.global_transform = position_node.global_transform
