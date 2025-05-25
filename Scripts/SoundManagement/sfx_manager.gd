extends Node
class_name SFXManager

@export var audio_player:AudioStreamPlayer
@export var sound_library:Dictionary
@export var pitch_range:Vector2=Vector2(1.0,1.0)

func _ready() -> void:
	audio_player.bus = "SFX"
	
func play_random(override_pitch_range:Vector2=Vector2.ZERO) -> void:
	var possible_streams:Array[AudioStream]
	for key in sound_library.keys():
		possible_streams.append(sound_library[key])
		
	audio_player.stream = possible_streams[randi_range(0,possible_streams.size()-1)]
	
	if override_pitch_range!=Vector2.ZERO:
		audio_player.pitch_scale = randf_range(override_pitch_range.x,override_pitch_range.y)
	else:
		audio_player.pitch_scale = randf_range(pitch_range.x,pitch_range.y)
		
	audio_player.play()
	
func play_sound(sound_name:String, pitch_position:float=0.5) -> void:
	if !sound_library.has(sound_name):
		push_error("Cannot find sound with name %s in the sfx sound library" % sound_name)
		return
	
	audio_player.stream = sound_library[sound_name]
	audio_player.pitch_scale = lerpf(pitch_range.x,pitch_range.y,pitch_position)
	audio_player.play()
		

var prev_random_id = -1
func select_clip(clip_id:int = -1) -> AudioStream:
	if sound_library.size() == 0:
		return null
		
	if clip_id != -1:
		return sound_library[clip_id]
	else:
		var possible_clips:Array[int]
		for i in range(sound_library.size()):
			if i != prev_random_id:
				possible_clips.append(i)
		var selected_clip_id = randi_range(0,possible_clips.size()-1)
		prev_random_id = selected_clip_id
		return sound_library[selected_clip_id]
		
		
	
