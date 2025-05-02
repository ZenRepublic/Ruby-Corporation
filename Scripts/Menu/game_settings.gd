extends Node
class_name GameSettings

@export var music_slider:Slider
@export var sfx_slider:Slider

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_slider.value = MusicManager.music_volume
	sfx_slider.value = MusicManager.sfx_volume
	
	music_slider.value_changed.connect(adjust_music_volume)
	sfx_slider.value_changed.connect(adjust_sfx_volume)
	pass # Replace with function body.

func adjust_music_volume(value:float) -> void:
	MusicManager.set_music_volume(value)
	MusicManager.play_sound("Slider",lerp(0.9,1.2,value))
	
func adjust_sfx_volume(value:float) -> void:
	MusicManager.set_sfx_volume(value)
	MusicManager.play_sound("Slider",lerp(0.9,1.2,value))
	
