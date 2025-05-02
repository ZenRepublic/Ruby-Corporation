extends Node
class_name PanelPopper

@export var panels:Array[Control]
	
func pop_panel(panel_id:int,time_to_show:float) -> void:
	var panel:Control = panels[panel_id]
	panel.scale=Vector2.ZERO
	panel.visible=true
	await tween_scale(panel,Vector2.ONE)
	await get_tree().create_timer(time_to_show).timeout
	await tween_scale(panel,Vector2.ZERO)
	panel.visible=false
	
func tween_scale(panel:Control,end_scale:Vector2) -> void:
	var tween:Tween = get_tree().create_tween()
	tween.tween_property(panel,"scale",end_scale,0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
