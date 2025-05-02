extends CanvasLayer
class_name TransitionScene

@export var fade_duration:float = 0.5

var fade_progress:float = 0.0

func fade_in() -> void:
	var last_time = Time.get_ticks_msec()
	
	var fade_time_elapsed:float=0.0
	while fade_progress<1.0:
		await get_tree().process_frame
		var current_time = Time.get_ticks_msec()
		var delta = (current_time - last_time) / 1000.0
		last_time = current_time
		
		fade_time_elapsed += delta
		fade_time_elapsed = clamp(fade_time_elapsed,0,fade_duration)
		fade_progress = lerp(0.0,1.0,fade_time_elapsed/fade_duration)

func fade_out() -> void:	
	var last_time = Time.get_ticks_msec()
	
	var fade_time_elapsed:float=0.0
	while fade_progress>0.0:
		await get_tree().process_frame
		var current_time = Time.get_ticks_msec()
		var delta = (current_time - last_time) / 1000.0
		last_time = current_time
		
		fade_time_elapsed += delta
		fade_time_elapsed = clamp(fade_time_elapsed,0,fade_duration)
		fade_progress = lerp(1.0,0.0,fade_time_elapsed/fade_duration)
	
