extends AudioStreamPlayer
class_name SFXManager

@export var clip_pool:Array[AudioStream]
@export_range(0.0,1.0) var min_pitch:float = 1.0
@export_range(1.0,2.0) var max_pitch:float = 1.0
	
func get_clip(id:int) -> AudioStream:
	return clip_pool[id]
	
func play_sound(clip_id:int = -1) -> void:
	if clip_pool.size() > 0:
		stream = select_clip(clip_id)
	
	pitch_scale = randf_range(min_pitch,max_pitch)
	play()
		

var prev_random_id = -1
func select_clip(clip_id:int = -1) -> AudioStream:
	if clip_pool.size() == 0:
		return null
		
	if clip_id != -1:
		return clip_pool[clip_id]
	else:
		var possible_clips:Array[int]
		for i in range(clip_pool.size()):
			if i != prev_random_id:
				possible_clips.append(i)
		var selected_clip_id = randi_range(0,possible_clips.size()-1)
		prev_random_id = selected_clip_id
		return clip_pool[selected_clip_id]
		
		
	
