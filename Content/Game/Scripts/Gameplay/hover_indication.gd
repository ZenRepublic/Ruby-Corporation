extends Node
class_name HoverIndication

@export var default_color:Color
@onready var visual:Sprite2D = $Visual
@onready var animator:AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func setup(grid_pos:Vector2) -> void:
	visual.visible=false
	self.global_position = Vector2(grid_pos.x*visual.texture.get_width(),grid_pos.y*visual.texture.get_height())
	
func show(color_modulate:Color=default_color) -> void:
	visual.self_modulate = color_modulate
	visual.visible=true
	animator.play("Move")
	pass
	
func hide() -> void:
	visual.visible=false
	animator.stop()
