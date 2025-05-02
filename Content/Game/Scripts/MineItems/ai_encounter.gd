extends MineItem
class_name AIEncounter

@export_file("*.json") var encounter_data_path:String
@export_file("*.txt") var ruleset:String
@export_multiline var visual_artstyle:String

@export var max_power:int = 10
@export var max_reward:int = 420

@onready var encounter_popup:EncounterPopup = $EncounterPopup

var character:String
var agenda:String
var power:int

var reward:int

var session_id:String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	encounter_popup.visible=false
	
	select_character_data()
	pass # Replace with function body.

func select_character_data() -> void:
	var file = FileAccess.open(encounter_data_path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	json.parse(content)
	var data = json.get_data()

	var rand_character:int = randi_range(0,data["characters"].size())
	var rand_agenda:int = randi_range(0,data["agendas"].size())
	character = data["characters"][rand_character]
	agenda = data["agendas"][rand_agenda]
	power = randi_range(1,max_power)
	reward = roundi(float(max_reward)/max_power)*power
	
	session_id = character.sha256_text()
	
func uncover() -> void:
	super.uncover()
	#play a transition effect while the prompt loads up, then instantiate fight scene
	var message = "New Encounter! \n"
	message += "Character: %s \n" % character
	message += "Agenda:  %s \n" % agenda
	message += "Power: %s/%s" % [power,max_power] 
	
	var file = FileAccess.open(ruleset, FileAccess.READ)
	var prompt_rules = file.get_as_text()
	OpenAI.setup_session(session_id,prompt_rules)

	var response:String = await OpenAI.prompt_session(message,session_id)
	var texture:Texture2D = await OpenAI.image_prompter.generate_image(visual_artstyle+"\n"+character+"\n"+agenda)
	var json = JSON.new()
	json.parse(response)
	var data = json.get_data()
	encounter_popup.setup(data["introduction"],data["actions"], texture)
	encounter_popup.connect("on_action_selected", process_encounter_outcome)

func process_encounter_outcome(action_selected:String) -> void:
	var response:String = await OpenAI.prompt_session(action_selected,session_id)
	print(response)
