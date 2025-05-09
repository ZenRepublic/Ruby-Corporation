extends Node
class_name GigManager

@export var gigs:Array[ClubhouseGig]

@export var mini_gig_spawn:Control
@export var mini_gig_display_scn:PackedScene
@export var display_scn:PackedScene
@export var gig_creator_scn:PackedScene

var mini_displays:Array[GigDisplay]

var active_gig:ClubhouseGig=null

signal on_gig_selected(gig:ClubhouseGig)

func _ready() -> void:
	show_gigs()
	
	for display in mini_displays:
		display.on_selected.connect(select_gig)
	
	
func show_gigs() -> void:
	for gig in gigs:
		var mini_instance:GigDisplay = mini_gig_display_scn.instantiate()
		mini_gig_spawn.add_child(mini_instance)
		mini_gig_spawn.move_child(mini_instance,0)
		mini_instance.setup_mini(gig)
		mini_displays.append(mini_instance)
		
func select_gig(display:GigDisplay, gig:ClubhouseGig) -> void:
	active_gig = gig
	ClubhouseProgram.utils.set_house_data(gig.mainnet_house_id,gig.devnet_house_id)
	show_gig_details(gig)
	
func show_gig_details(gig:ClubhouseGig) -> void:
	var display:GigDisplay = display_scn.instantiate()
	get_tree().root.add_child(display)
	
	display.setup_full(gig)
	display.on_selected.connect(handle_selection)
	display.on_create_pressed.connect(pop_campaign_creator)
	
func handle_selection(display:GigDisplay, gig:ClubhouseGig) -> void:
	on_gig_selected.emit(gig)
	display.queue_free()
	
func pop_campaign_creator(display:GigDisplay, gig:ClubhouseGig) -> void:
	active_gig = gig
	
	var creator_instance:CampaignCreator = gig_creator_scn.instantiate()
	get_tree().root.add_child(creator_instance)
	
	display.queue_free()
	
	
