extends Node
class_name ScreenSizer

func _process(delta:float) -> void:
	var curr_window_size:Vector2 = DisplayServer.window_get_size()
	var screen_ratio = curr_window_size.x / curr_window_size.y

	# Target aspect ratio (e.g., 9:16 for portrait)
	var target_ratio = 9.0 / 16.0

	var new_size:Vector2
	if screen_ratio > target_ratio:
		# Wider than target; adjust width
		new_size = Vector2(curr_window_size.y * target_ratio, curr_window_size.y)
	else:
		# Taller than target; adjust height
		new_size = Vector2(curr_window_size.x, curr_window_size.x / target_ratio)
	
	DisplayServer.window_set_size(new_size)
	
	# Optionally, lock the screen orientation
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
