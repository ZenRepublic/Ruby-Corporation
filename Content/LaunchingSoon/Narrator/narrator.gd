extends Node
class_name Narrator

@export var sound_library:Dictionary
@export var groans:Array[AudioStream]
@export var encouragements:Array[AudioStream]
@export var audio_source:AudioStreamPlayer

func _init() -> void:
	add_to_group("Narrator")

func say(sound_name:String) -> void:
	print(sound_name)
	var sound:AudioStream = sound_library[sound_name]
	audio_source.stream = sound
	audio_source.play()
	
func play_groan() -> void:
	var random_idx:int = randi_range(0,groans.size()-1)
	audio_source.stream = groans[random_idx]
	audio_source.play()
	
func play_encourgement(place_tier:LaunchSettings.PLACE_TIER) -> void:
#	place tier 0 is NONE in the argument and 1st sound is Sloppy, so gotta do -1
	audio_source.stream = encouragements[place_tier-1]
	audio_source.play()
