extends Button
class_name TimedButton

## Very Interesting hack. If prefix has ":" then it shows time after it.
@export var pre_start_prefix:String = "Starts in:"
@export var time_left_prefix:String = "Closes in:"
@export var activated_text:String
@export var refresh_frequency_seconds:int = 1

@export var enable_on_started:bool=true
@export var enable_on_finished:bool=true

var start_time:float=0
var end_time:float=0
var time_elapsed:float

var tracked_time:float

var is_active:bool=false

signal on_timer_started
signal on_timer_finished
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#disabled=true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !is_active:
		return
	
	time_elapsed+=delta
	if time_elapsed < refresh_frequency_seconds:
		return
		
	var curr_time:float = Time.get_unix_time_from_system()
	
	if tracked_time == start_time and curr_time >= start_time:
		on_timer_started.emit()
		if enable_on_started:
			disabled=false
		tracked_time = end_time
		
	if tracked_time == end_time and curr_time >= end_time:
		if enable_on_finished:
			disabled=false
		text = activated_text
		is_active=false
		on_timer_finished.emit()
		return
	
	text = format_text(tracked_time)
	time_elapsed=0

func start_timer(start_timestamp:float,end_timestamp:float) -> void:
	start_time = start_timestamp
	end_time = end_timestamp
	
	is_active=true
	tracked_time = start_time
	time_elapsed = refresh_frequency_seconds
	
func is_finished() -> bool:
	if end_time == 0:
		return false
		
	var curr_time:float = Time.get_unix_time_from_system()
	return tracked_time == end_time and curr_time > tracked_time

func get_prefix() -> String:
	if tracked_time == start_time:
		return pre_start_prefix
	else:
		return time_left_prefix
		
func format_text(time:float) -> String:
	var prefix:String
	if time == start_time:
		prefix = pre_start_prefix
	else:
		prefix = time_left_prefix
		
	var formatted_text:String
	if ":" in prefix:
		var parts = prefix.split(":", true, 2)
		formatted_text = parts[0] + ": " + timestamp_to_time(time)
	else:
		formatted_text = prefix
		
	return formatted_text
	
func timestamp_to_time(time:float) -> String:
	var timestamp:int = time - Time.get_unix_time_from_system()
	var hours = int(timestamp / 3600)
	var minutes = int((timestamp % 3600) / 60)
	var seconds = int(timestamp % 60)
	
	var formatted_time:String = str(hours) + "h " + str(minutes) + "m " 
	if refresh_frequency_seconds/60.0 < 1:
		formatted_time += str(seconds) + "s"
		
	return formatted_time
