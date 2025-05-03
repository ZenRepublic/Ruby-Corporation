extends Control
class_name AdminPanel

@export var progress_label:Label
@export var token_visual:TextureRect
@export var score_label:NumberLabel

@export var warnings_container:HBoxContainer
@export var warning_visual:Texture2D

var launch_controller:LaunchController
	
func _ready() -> void:	
	score_label.set_value(0)
	
	launch_controller = get_tree().get_first_node_in_group("LaunchController") as LaunchController
	launch_controller.on_floor_changed.connect(update_floor_progress)
	launch_controller.on_salary_updated.connect(update_salary_display)
	launch_controller.on_warning_received.connect(update_warnings_display)
	
	token_visual.texture = ImageTexture.create_from_image(launch_controller.get_token_visual())
	
func update_salary_display(new_score:float) -> void:
	score_label.set_value(new_score)
	
func update_floor_progress(curr_floor) -> void:
	progress_label.text = "%s / %s Parts Placed" %[curr_floor,LaunchSettings.CARGO_TO_FULL]
	
func update_warnings_display(new_warning_amount:int) -> void:
	var curr_warnings:int = warnings_container.get_child_count()
	if new_warning_amount == curr_warnings:
		return
		
	if new_warning_amount < curr_warnings:
		var warnings_to_remove:int = curr_warnings-new_warning_amount
		for i in range(warnings_to_remove):
			warnings_container.get_children()[warnings_container.get_child_count()-1].queue_free()
	elif new_warning_amount > curr_warnings:
		var warnings_to_add:int = new_warning_amount - curr_warnings
		for i in range(warnings_to_add):
			var warning:TextureRect = TextureRect.new()
			warning.texture = warning_visual
			warning.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			warning.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			warnings_container.add_child(warning)
	
