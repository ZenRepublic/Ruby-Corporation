extends TransitionScene

@export var transition_texture:TextureRect
@export var loading_panel:Control
@export var sfx_manager:SFXManager

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
	sfx_manager.play_sound("FadeIn")
	
func show_loading_panel() -> void:
	loading_panel.visible=true

func handle_fade_out() -> void:
	sfx_manager.play_sound("FadeOut")
	await get_tree().create_timer(0.3).timeout
	loading_panel.visible=false
