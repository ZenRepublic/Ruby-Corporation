extends Node
class_name GigSelector

@export var gigs:Array[ClubhouseGig]

@export var gig_spawn:Control
@export var gig_display_scn:PackedScene

var gig_displays:Array[GigDisplay]

signal on_gig_selected(gig:ClubhouseGig)

func _ready() -> void:
	show_gigs()
	
func show_gigs() -> void:
	for gig in gigs:
		var gig_display_instance:GigDisplay = gig_display_scn.instantiate()
		gig_spawn.add_child(gig_display_instance)
		gig_spawn.move_child(gig_display_instance,0)
		
		gig_display_instance.on_selected.connect(select_gig)
		gig_display_instance.setup_display(gig)
		
		gig_displays.append(gig_display_instance)
		
func select_gig(gig:ClubhouseGig) -> void:
	on_gig_selected.emit(gig)

	
	
