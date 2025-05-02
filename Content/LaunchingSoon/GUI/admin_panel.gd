extends Control
class_name AdminPanel

@export var base_place_label:Label
@export var progress_label:Label

@export var score_label:NumberLabel

@export var warnings_container:HBoxContainer
@export var warning_visual:Texture2D

var launch_controller:LaunchController
	
func _ready() -> void:
	base_place_label.visible=true
	progress_label.visible=false
		
	score_label.set_value(0)
	
	launch_controller = get_tree().get_first_node_in_group("LaunchController") as LaunchController
	launch_controller.on_floor_changed.connect(update_floor_progress)
	launch_controller.on_salary_updated.connect(update_salary_display)
	launch_controller.on_warning_received.connect(update_warnings_display)
	
func update_salary_display(new_score:float) -> void:
	var curr_score: float = score_label.get_number_value()
	var difference: float = new_score - curr_score

	if difference == 0:
		return

	# Adjust increment based on difference size for consistent animation speed
	var increment: float = LaunchSettings.get_max_placement_score()/20.0
	increment = snappedf(increment,0.02)
	var target_score: float = new_score

	while abs(target_score - curr_score) > abs(increment):
		curr_score += increment
		score_label.set_value(curr_score)
		await get_tree().create_timer(0.03).timeout

	# Set final score to avoid overshooting
	score_label.set_value(new_score)
	
func update_floor_progress(curr_floor) -> void:
	if base_place_label.visible:
		base_place_label.visible=false
		progress_label.visible=true
	
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
	
