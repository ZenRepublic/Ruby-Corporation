extends Node

@export var transition_panels:Array[PackedScene]
@export var debug_window_size:Vector2

@onready var particle_cache:ParticleCache = $ParticleCache

signal fade_in_started
signal fade_in_ended
signal fade_out_started
signal fade_out_ended

signal on_scene_loaded
signal scene_transition_started
signal scene_transition_finished

var scene_to_load_path:String
var curr_fade_amount:float=0.0
var fade_duration:float	

var load_progress:float = 0.0
var allow_scene_change:bool=false

var previous_scene_path:String
var curr_scene_path:String

var transition_instance:TransitionScene

var interscene_data:Dictionary

func _ready() -> void:
	curr_scene_path = get_tree().current_scene.scene_file_path
	
	if OS.has_feature("debug"):
		DisplayServer.window_set_size(debug_window_size)  # or any dev-friendly size
		var screen_middle_point:Vector2 = DisplayServer.screen_get_size() / 2
		var place_position:Vector2 = screen_middle_point - debug_window_size/2
		DisplayServer.window_set_position(place_position)
		
		
func _process(_delta: float) -> void:
	if scene_to_load_path=="":
		return
		
	var progress:Array
	var status = ResourceLoader.load_threaded_get_status(scene_to_load_path,progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		load_progress = progress[0]
	elif status == ResourceLoader.THREAD_LOAD_LOADED && allow_scene_change:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene_to_load_path))
		on_scene_loaded.emit()
		allow_scene_change=false
		curr_scene_path = scene_to_load_path
		scene_to_load_path=""
		if transition_instance!=null:
			finalize_scene_transition()
		
func reload_scene(fade_between_scenes:bool=true,transition_id:int=-1,scene_data:Dictionary={}) -> void:
	load_scene(curr_scene_path,fade_between_scenes,transition_id,0.0,scene_data)
	
func load_previous_scene(fade_between_scenes:bool=true,transition_id:int=-1,wait_time:float=0.0,scene_data:Dictionary={}) -> void:
	if previous_scene_path == "":
		return
	load_scene(previous_scene_path,fade_between_scenes,transition_id,wait_time,scene_data)	

func load_scene(scene_path:String,fade_between_scenes:bool=true,transition_id:int=-1,wait_time:float=0.0,scene_data:Dictionary={}) -> void:
#	don't set this scene as previous scene if its reloading the same one
	if scene_path != get_tree().current_scene.scene_file_path:
		previous_scene_path = get_tree().current_scene.scene_file_path
		
	if wait_time > 0.0:
		await get_tree().create_timer(wait_time).timeout
		
	if scene_data.size()>0:
		for key in scene_data.keys():
			#if !interscene_data.has(key):
			interscene_data[key] = scene_data[key]
	#print(interscene_data)
	
	scene_to_load_path = scene_path
	print("Loading: ",scene_to_load_path)
	scene_transition_started.emit()
	
	if fade_between_scenes:
		self.fade_duration = fade_duration
		transition_instance = select_transition_scene(transition_id).instantiate()
		add_child(transition_instance)
	
	if ResourceLoader.has_cached(scene_path):
		ResourceLoader.load_threaded_get(scene_path)
	else:
		ResourceLoader.load_threaded_request(scene_path)
	
	if fade_between_scenes:
		fade_in_started.emit()
		await transition_instance.fade_in()
		fade_in_ended.emit()
		
	await particle_cache.cache_particles(scene_path)
	
	allow_scene_change = true
	
func finalize_scene_transition() -> void:
	fade_out_started.emit()
	await transition_instance.fade_out()
	fade_out_ended.emit()
	transition_instance.queue_free()
	
	scene_transition_finished.emit()
		
	
func select_transition_scene(id:int) -> PackedScene:
	if id == -1:
		return transition_panels[randi_range(0,transition_panels.size()-1)]
	else:
		return transition_panels[id]
		
func get_interscene_data(key):
	if interscene_data.has(key):
		return interscene_data[key]
	else:
		return null
		
