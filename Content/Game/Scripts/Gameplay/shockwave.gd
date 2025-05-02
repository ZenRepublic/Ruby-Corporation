extends Node
class_name Shockwave

@export var default_force:float = 0.4
@export var default_size:float = 0.3
@export var default_thickness:float = 0.08

@onready var shockwave_rect:ColorRect = $ColorRect

var wave_strength:float

func send_shockwave(screen_pos:Vector2,player_cam:Camera2D,strength:float = 1.0) -> void:
	wave_strength = strength * player_cam.zoom.x
	var mat:ShaderMaterial = shockwave_rect.material
	
	var viewport_size:Vector2 = Vector2(get_viewport().get_visible_rect().size) 
	var wave_pos:Vector2 = Vector2(screen_pos.x/viewport_size.x,screen_pos.y/viewport_size.y)
	#need to adjust for scaledUVs 
	var aspect_ratio = viewport_size.x / viewport_size.y
	wave_pos.x = (wave_pos.x - 0.5) * aspect_ratio + 0.5
	
	mat.set_shader_parameter("center",wave_pos)
	
	var tween = get_tree().create_tween();
	tween.tween_method(process_shock_animation, 0.0, 1.0, 0.5)
	
func process_shock_animation(value:float) -> void:
	var mat:ShaderMaterial = shockwave_rect.material
	mat.set_shader_parameter("force",lerp(default_force*wave_strength,0.0,value))
	mat.set_shader_parameter("size",lerp(0.0,default_size*wave_strength,value))
	mat.set_shader_parameter("thickness",lerp(default_thickness*wave_strength,default_thickness*wave_strength/2,value))
