extends Control
class_name AdminPanel

@export var progress_label:Label
@export var progress_bar:ProgressBar
@export var token_visual:TextureRect
@export var score_label:NumberLabel

@export var warnings_container:HBoxContainer
@export var warning_visual:Texture2D

@export var explanation_text:Control
	
func _ready() -> void:	
	progress_label.text = str(LaunchSettings.CARGO_TO_FULL)
	progress_bar.max_value = LaunchSettings.CARGO_TO_FULL
	
	score_label.set_value(0)
	update_floor_progress(0)
	
	#token_visual.texture = ImageTexture.create_from_image(launch_controller.get_token_visual())

func set_token_visual() -> void:
	var token_tex:Texture2D = ClubhouseProgram.claimer.get_reward_token_texture()
	if token_tex == null:
		return
	
	token_visual.texture = token_tex
	
func update_launchpad_value_display(new_score:float) -> void:
	score_label.set_value(new_score)
	
func update_floor_progress(curr_floor) -> void:
	progress_bar.value = curr_floor
	
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
	
