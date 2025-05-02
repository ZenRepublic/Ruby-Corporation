extends Node

@export var music_library:Dictionary
@export var sound_library:Dictionary
@export var default_fade_duration:float = 1.0
@onready var music_player:AudioStreamPlayer = $MusicPlayer
@onready var sfx_player:AudioStreamPlayer = $SFXPlayer

var music_volume:float = 1.0
var sfx_volume:float = 1.0

var curr_fade_duration:float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func play_sound(sound_name:String,pitch_scale:float=1.0) -> void:
	if sfx_player.stream != sound_library[sound_name]:
		sfx_player.stream = sound_library[sound_name]
		
	sfx_player.pitch_scale = pitch_scale
	sfx_player.play()
	
func play_song(song_name:String,fade_from_previous:bool=true,fade_duration:float=-1) -> void:
	if !music_library.has(song_name):
		push_error("Song Doesnt exist in library")
		return
		
	if fade_duration == -1:
		curr_fade_duration = default_fade_duration
	else:
		curr_fade_duration = fade_duration
		
	var song:AudioStream = music_library[song_name]
	
	var audio_bus:int = AudioServer.get_bus_index("Music")
	if music_player.stream!=null && fade_from_previous:
		await fade_out(audio_bus,music_volume)
	music_player.stream = song
	music_player.play()
	
	if fade_from_previous:
		await fade_in(audio_bus,music_volume)
	
	
func pause_all_sounds() -> void:
	var master_bus_index:int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index,true)

func resume_all_sounds() -> void:
	var master_bus_index:int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index,false)
	
func set_music_volume(value:float) -> void:
	music_volume = value
	var audio_bus:int = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(audio_bus,linear_to_db(music_volume))
func set_sfx_volume(value:float) -> void:
	sfx_volume = value
	var audio_bus:int = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(audio_bus,linear_to_db(sfx_volume))
	
func fade_in(bus_index:int,max_volume:float) -> void:
	var last_time = Time.get_ticks_msec()
	
	var fade_time_elapsed:float=0.0
	while fade_time_elapsed<curr_fade_duration:
		await get_tree().process_frame
		var current_time = Time.get_ticks_msec()
		var delta = (current_time - last_time) / 1000.0
		last_time = current_time
		
		fade_time_elapsed += delta
		fade_time_elapsed = clamp(fade_time_elapsed,0,curr_fade_duration)
		var fade_progress:float = lerp(0.0,max_volume,fade_time_elapsed/curr_fade_duration)
		AudioServer.set_bus_volume_db(bus_index,linear_to_db(fade_progress))
		

func fade_out(bus_index:int,max_volume:float) -> void:	
	var last_time = Time.get_ticks_msec()
	
	var fade_time_elapsed:float=0.0
	while fade_time_elapsed<curr_fade_duration:
		await get_tree().process_frame
		var current_time = Time.get_ticks_msec()
		var delta = (current_time - last_time) / 1000.0
		last_time = current_time
		
		fade_time_elapsed += delta
		fade_time_elapsed = clamp(fade_time_elapsed,0,curr_fade_duration)
		var fade_progress:float = lerp(max_volume,0.0,fade_time_elapsed/curr_fade_duration)
		AudioServer.set_bus_volume_db(bus_index,linear_to_db(fade_progress))
