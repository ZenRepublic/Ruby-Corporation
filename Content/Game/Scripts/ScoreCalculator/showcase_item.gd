extends Node
class_name ShowcaseItem

@onready var animation_player:AnimationPlayer = $AnimationPlayer
@onready var visual:TextureRect = $Visual

@export var jump_rate:float = 1.2

var landed:bool = false
# Called when the node enters the scene tree for the first time.
var time_to_next_jump:float = 0.0
func _process(delta: float) -> void:
	if !landed:
		return
		
	time_to_next_jump -= delta
	if time_to_next_jump < 0:
		jump()
		time_to_next_jump = jump_rate
		
func setup(image:Texture2D) -> void:
	if visual == null:
		visual = $Visual
		
	visual.texture = image
	visual.size = Vector2(image.get_width(),image.get_height())
	visual.pivot_offset = Vector2(visual.texture.get_width()/2.0,visual.texture.get_height())
	
	visual.position = Vector2(-visual.texture.get_width()/2.0,-visual.texture.get_height()*2.5)
		

func drop() -> void:
	#var final_height_offset:float = randi_range(-20,60)
	var final_pos:Vector2 = Vector2(-visual.texture.get_width()/2.0,-visual.texture.get_height())
	
	animation_player.play("Drop")
	var tween = get_tree().create_tween()
	tween.tween_property(visual,"position",final_pos,0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	landed=true
	
	
func jump() -> void:	
	var original_pos = visual.position
	var jump_pos:Vector2 = visual.position + Vector2(0,-30)
	var tween = get_tree().create_tween()
	tween.tween_property(visual,"position",jump_pos,0.2).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	tween.chain().tween_property(visual,"position",original_pos,0.2).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	time_to_next_jump = jump_rate
	
	
