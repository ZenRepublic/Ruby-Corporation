extends Node2D
class_name PlayerInput

enum GameDevice{PC,MOBILE}

@export var mouse_sensitivity:float = 2.0
@export var neutral_cursor:Texture2D
@export var pressed_cursor:Texture2D
@export var cursor_hotspot:Vector2
var start_pos

var mouse_position:Vector2
var is_clicked:bool=false
var input_enabled:bool=true
var mouse_active:bool=true

var touch_positions: Dictionary = {} 
var prev_touch_position_size:int
var prev_drag_position:Vector2
var is_pinch:bool=false
var prev_pinch_distance:float

var game_device:GameDevice

signal on_zoom(zoom_point:Vector2,factor:float)
signal on_reset
signal on_drag(move_delta:Vector2)
signal on_click(click_pos:Vector2)
signal on_click_release(click_pos:Vector2)
signal on_right_click(is_pressed:bool)
signal on_escape

func _ready() -> void:
	game_device = get_game_device()
	show_mouse(game_device == GameDevice.PC)
	#game_device = GameDevice.MOBILE
	#show_mouse(true)
	
func get_game_device() -> GameDevice:
	if OS.get_name() == "Web":
		var is_web_mobile: bool = JavaScriptBridge.eval("
	(/windows phone/i.test(navigator.userAgent || navigator.vendor || window.opera) || 
	 /android/i.test(navigator.userAgent || navigator.vendor || window.opera) || 
	 (/iPad|iPhone|iPod/.test(navigator.userAgent || navigator.vendor || window.opera) && !window.MSStream) || 
	 (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 0))", true)
	
		if is_web_mobile:
			return GameDevice.MOBILE
		else:
			return GameDevice.PC
	else:
		return GameDevice.PC
		
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Reset"):
		on_reset.emit()
		

func _input(event: InputEvent) -> void:		
	if !input_enabled:
		return
	
	if event.is_action_pressed("Escape"):
		on_escape.emit()
		
	match game_device:
		GameDevice.PC:
			if event is InputEventMouseButton:	
				var mouse_pos:Vector2 = get_global_mouse_position()
				if event.button_index == MOUSE_BUTTON_LEFT:
					if event.is_pressed():
						Input.set_custom_mouse_cursor(pressed_cursor,Input.CursorShape.CURSOR_ARROW,cursor_hotspot)
						on_click.emit(mouse_pos)
					else:
						Input.set_custom_mouse_cursor(neutral_cursor,Input.CursorShape.CURSOR_ARROW,cursor_hotspot)
						on_click_release.emit(mouse_pos)
					is_clicked = event.is_pressed()
					
				if event.button_index == MOUSE_BUTTON_RIGHT:
					on_right_click.emit(event.is_pressed())

						
				if event.button_index == MOUSE_BUTTON_WHEEL_UP && event.is_pressed():
					on_zoom.emit(mouse_pos,1.1)
				if event.button_index == MOUSE_BUTTON_WHEEL_DOWN && event.is_pressed():
					on_zoom.emit(mouse_pos,0.9)
					
			if event is InputEventMouseMotion and is_clicked:
				mouse_position = event.position
				#sent inverted event.relative because thats more intuitive to scroll
				on_drag.emit(-event.relative*mouse_sensitivity)
					
		GameDevice.MOBILE:
			if event is InputEventScreenTouch:
				var canvas_transform = get_viewport().get_canvas_transform()
				touch_positions[event.index] = event.position
				if event.pressed: 
					if touch_positions.size() == 1 and !is_pinch:
						on_click.emit(canvas_transform.affine_inverse() * get_middle_touch_position())
				else:
					if touch_positions.size() == 1 and !is_pinch:
						on_click_release.emit(canvas_transform.affine_inverse() * get_middle_touch_position())
					touch_positions.erase(event.index)

			if event is InputEventScreenDrag:
				if event.index in touch_positions:
					touch_positions[event.index] = event.position
				
				if touch_positions.size() != prev_touch_position_size:
					prev_drag_position = Vector2.ZERO
				#sent inverted event.relative because thats more intuitive to scroll
				if prev_drag_position != Vector2.ZERO:
					var drag_delta:Vector2 = get_middle_touch_position() - prev_drag_position
					on_drag.emit(-drag_delta)
					
				prev_drag_position = get_middle_touch_position()
				prev_touch_position_size = touch_positions.size()
					
			if touch_positions.size() == 2:
				is_pinch = true
				var input_positions:Array = touch_positions.values()
				var pinch_distance:float = input_positions[0].distance_to(input_positions[1])
				if prev_pinch_distance > 0:
					var zoom_factor = pinch_distance / prev_pinch_distance
					zoom_factor = clamp(zoom_factor,0.98,1.02)
					on_zoom.emit(get_middle_touch_position(),zoom_factor)
				prev_pinch_distance = pinch_distance
			else:
				prev_pinch_distance = 0
				
			if touch_positions.size() == 0:
				if is_pinch:
					is_pinch = false
				prev_drag_position = Vector2.ZERO
				
func set_input_active(state:bool) -> void:
	input_enabled = state
	
#	reset touch positions
	touch_positions.clear()
	prev_touch_position_size=0
	
	
func show_mouse(state:bool) -> void:
	mouse_active=state
	
	if state==true:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func get_middle_touch_position() -> Vector2:
	var total_position = Vector2.ZERO
	for pos in touch_positions.values():
		total_position += pos
	return total_position / touch_positions.size()
