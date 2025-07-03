extends Node
class_name GigOverview

@export var campaign_creator_scn:PackedScene
@export var gig_display:GigDisplay
@export var campaign_loader:CampaignLoader

var active_gig:ClubhouseGig=null

var menu_manager:MenuManager

func _ready() -> void:
	menu_manager = get_tree().get_first_node_in_group("MenuManager")
	pass

		
func setup_gig(gig:ClubhouseGig) -> void:
	active_gig = gig
	ClubhouseProgram.utils.set_house_data(gig.mainnet_house_id,gig.devnet_house_id)
	
	gig_display.set_basic_fields(gig)
	gig_display.description_label.text = gig.description
	
	campaign_loader.load_campaigns()

	
func free_play() -> void:
	menu_manager.load_gig_free_mode()
	
func pop_campaign_creator() -> void:
	var creator_instance:CampaignCreator = campaign_creator_scn.instantiate()
	get_tree().root.add_child(creator_instance)
