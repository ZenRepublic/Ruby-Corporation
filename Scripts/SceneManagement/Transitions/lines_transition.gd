extends TransitionScene

@export var transition_texture:TextureRect
@export var loading_panel:Control
@export var audio_player:AudioStreamPlayer
@export var fade_in_sound:AudioStreamMP3
@export var fade_out_sound:AudioStreamMP3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	loading_panel.visible=false
	
	SceneManager.fade_in_started.connect(start_transition)
	SceneManager.fade_in_ended.connect(show_loading_panel)
	SceneManager.fade_out_started.connect(handle_fade_out)
	pass # Replace with function body.

func _process(_delta: float) -> void:
	transition_texture.material.set_shader_parameter("progress",fade_progress)
	
	
func start_transition() -> void:
	if fade_in_sound!=null:
		audio_player.stream= fade_in_sound
		audio_player.play()
	
func show_loading_panel() -> void:
	loading_panel.visible=true

func handle_fade_out() -> void:
	if fade_out_sound!=null:
		audio_player.stream= fade_out_sound
		audio_player.play()
	await get_tree().create_timer(0.3).timeout
	loading_panel.visible=false
