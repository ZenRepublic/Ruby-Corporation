extends Node
class_name EncounterPopup

@export var action_button_scn:PackedScene
@export var text_speed:float = 0.5

@onready var narration_box:Control = $EncounterBox/Narration
@onready var text_box:Label = $EncounterBox/Narration/Textbox
@onready var click_continue_indication:Label = $EncounterBox/Narration/ClickToContinue

@onready var action_container:HBoxContainer = $EncounterBox/Options
@onready var visual_box:TextureRect = $EncounterBox/Visual

var lines:Array
var player_actions:Array

var curr_line_id:int = 0

var player:PlayerManager

signal on_action_selected

func _process(delta: float) -> void:
	if !self.visible:
		return
		
	if text_box.visible_ratio<1:
		text_box.visible_ratio += text_speed*delta
		text_box.visible_ratio = clamp(text_box.visible_ratio,0.0,1.0)
	elif !click_continue_indication.visible:
		click_continue_indication.visible=true


func setup(text_lines:Array,actions:Array, visual:Texture2D) -> void:
	player = get_tree().get_first_node_in_group("Player")
	
	self.visible=true
	lines = text_lines
	player_actions = actions
	
	for action in actions:
		var action_instance:Button = action_button_scn.instantiate()
		action_container.add_child(action_instance)
		action_instance.text = action
		action_instance.pressed.connect(_on_action_selected.bind(action_instance))
		
		
	visual_box.texture = visual
	show_next_line()
	
func show_next_line() -> void:
	click_continue_indication.visible=false
	text_box.visible_ratio=0
	text_box.text = lines[curr_line_id]
	curr_line_id+= 1

func display_player_actions() -> void:
	narration_box.visible=false
	action_container.visible=true
	
func _on_action_selected(clicked_action:Button) -> void:
	on_action_selected.emit(clicked_action.text)
	action_container.visible=false
	
	
func _input(event: InputEvent) -> void:		
	if !self.visible:
		return
		
	if event is InputEventMouseButton:	
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				if text_box.visible_ratio<1:
					text_box.visible_ratio = 1
				else:
					if curr_line_id == lines.size():
						display_player_actions()
					else:
						show_next_line()
