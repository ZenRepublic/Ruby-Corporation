extends Line2D

@export var tool_manager:ToolManager
@export var wire_origin:Control

@export var ropeLength:float = 30.0
@export var constrain:float = 1.0	# distance between points
@export var gravity:Vector2 = Vector2(0,9.8)
@export var dampening:float = 0.9
@export var noise_strength:float=10
@export var noisiness:float = 1.0
@export var startPin:bool = true
@export var endPin:bool = true

var pos:PackedVector2Array
var posPrev:PackedVector2Array
var pointCount: int

func _ready()->void:
	pointCount = get_pointCount(ropeLength)
	resize_arrays()
	init_position()
	
	var wire_world_pos = (get_viewport().get_screen_transform() * get_viewport().get_canvas_transform()).affine_inverse() * wire_origin.global_position
	set_start(to_local(wire_world_pos))
	set_last(to_local(tool_manager.global_position))
	
	tool_manager.connect("on_tool_hit",zap_wire)

func get_pointCount(distance: float)->int:
	return int(ceil(distance / constrain))

func resize_arrays():
	pos.resize(pointCount)
	posPrev.resize(pointCount)

func init_position()->void:
	for i in range(pointCount):
		pos[i] = position + Vector2(constrain *i, 0)
		posPrev[i] = position + Vector2(constrain *i, 0)
	position = Vector2.ZERO

func _process(delta)->void:
	if tool_manager.mining_tools.visible:
		default_color = Color.WHITE
	else:
		default_color = Color(1,1,1,0)
		
	var wire_world_pos = get_viewport().get_canvas_transform().affine_inverse() * wire_origin.global_position
	set_start(to_local(wire_world_pos))
	set_last(to_local(tool_manager.active_tool.wire_point.global_position))
	
	update_points(delta)
	update_constrain()
	
	#update_constrain()	#Repeat to get tighter rope
	#update_constrain()
	
	# Send positions to Line2D for drawing
	points = pos

func set_start(p:Vector2)->void:
	pos[0] = p
	posPrev[0] = p

func set_last(p:Vector2)->void:
	pos[pointCount-1] = p
	posPrev[pointCount-1] = p

func update_points(delta)->void:
	for i in range (pointCount):
		# not first and last || first if not pinned || last if not pinned
		if (i!=0 && i!=pointCount-1) || (i==0 && !startPin) || (i==pointCount-1 && !endPin):
			var velocity = (pos[i] -posPrev[i]) * dampening
			posPrev[i] = pos[i]
			pos[i] += velocity + (gravity * delta)
			pos[i] += Vector2(randf_range(-noise_strength,noise_strength),randf_range(-noise_strength,noise_strength))*noisiness

func update_constrain()->void:
	for i in range(pointCount):
		if i == pointCount-1:
			return
		var distance = pos[i].distance_to(pos[i+1])
		var difference = constrain - distance
		var percent = difference / distance
		var vec2 = pos[i+1] - pos[i]
		
		# if first point
		if i == 0:
			if startPin:
				pos[i+1] += vec2 * percent
			else:
				pos[i] -= vec2 * (percent/2)
				pos[i+1] += vec2 * (percent/2)
		# if last point, skip because no more points after it
		elif i == pointCount-1:
			pass
		# all the rest
		else:
			if i+1 == pointCount-1 && endPin:
				pos[i] -= vec2 * percent
			else:
				pos[i] -= vec2 * (percent/2)
				pos[i+1] += vec2 * (percent/2)

func zap_wire(active_tool:MiningTool) -> void:
	var zap_strength:float
	match active_tool.tool_type:
		MiningTool.ToolType.CHISEL:
			zap_strength = 0.2
		MiningTool.ToolType.PICKAXE:
			zap_strength = 0.5
		MiningTool.ToolType.HAMMER:
			zap_strength = 1.0	
			
	var tween = get_tree().create_tween()
	tween.tween_property(self,"noisiness",zap_strength,0.2)
	tween.tween_property(self,"noisiness",0.0,0.2)
