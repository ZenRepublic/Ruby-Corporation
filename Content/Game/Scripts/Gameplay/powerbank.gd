extends Control
class_name Powerbank

@onready var energy_meter:ColorRect = $Fluid
@onready var battery_point:Control = $BatteryPoint
@onready var energy_display:Label = $EnergyDisplay

var player_manager:PlayerManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_manager = get_tree().get_first_node_in_group("Player")
	player_manager.stats.connect("on_energy_updated",update_energy_bar)


func update_energy_bar(curr_energy:int) -> void:
	var tween = get_tree().create_tween();
	var prev_value:float = energy_meter.material.get_shader_parameter("progress")
	var new_value:float = lerp(0.0,1.0,curr_energy/float(player_manager.stats.base_energy))
	tween.tween_method(animate_energy, prev_value, new_value, 0.3); # args are: (method to call / start value / end value / duration of animation)
	
func animate_energy(value:float) -> void:
	energy_meter.material.set_shader_parameter("progress",value)
#	value goes from 0 to 1, so remap it to 0-100 for percentage
	var energy_percentage:int = ceili(value*100)
	energy_display.text = "%s%%" % energy_percentage
