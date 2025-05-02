extends Node
class_name PlayerStats

@export var base_energy:int = 100

var energy:int

var inventory:Array[MineItem]

signal on_energy_updated(energy:int)
signal on_energy_depleted

func _ready() -> void:
	energy = base_energy
	on_energy_updated.emit(energy)

func use_energy(amount_to_use:int) -> void:
	energy -= amount_to_use
	energy = clamp(energy,0,base_energy)
	on_energy_updated.emit(energy)
	
	if energy == 0:
		on_energy_depleted.emit()
	
func restore_energy(amount_to_restore:int) -> void:
	energy += amount_to_restore
	energy = clamp(energy,0,base_energy)
	on_energy_updated.emit(energy)
