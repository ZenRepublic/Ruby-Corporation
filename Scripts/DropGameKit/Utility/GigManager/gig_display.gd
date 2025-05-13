extends Node
class_name GigDisplay

@export var title_label:Label
@export var tag_label:Label
@export var description_label:Label

@export var gig_visual:TextureRect
@export var visual_size:int = 512

@export var create_campaign_button:ButtonLock
@export var view_campaigns_button:BaseButton
@export var free_play_button:BaseButton
@export var external_visit_button:LinkedButton

var gig:ClubhouseGig

signal on_create_pressed(display:GigDisplay, gig:ClubhouseGig)
signal on_selected(display:GigDisplay, gig:ClubhouseGig)

func _ready() -> void:
	if view_campaigns_button!=null:
		view_campaigns_button.visible=false
	if free_play_button!=null:
		free_play_button.visible=false
	if external_visit_button!=null:
		external_visit_button.visible=false
		
	if create_campaign_button!=null:
		var program_admins:Array[Pubkey] = await ClubhouseProgram.utils.get_program_admin_list()
		create_campaign_button.set_address_list(program_admins)

func setup_mini(gig:ClubhouseGig) -> void:
	self.gig = gig
	set_basic_fields(gig)
	
func setup_full(gig:ClubhouseGig) -> void:
	self.gig = gig
	set_basic_fields(gig)
	
	description_label.text = gig.description
	
	if gig.is_external():
		external_visit_button.link = gig.link_to_game
		external_visit_button.visible=true
	else:
		view_campaigns_button.visible=true
		free_play_button.visible=true
	
	
func set_basic_fields(gig:ClubhouseGig) -> void:
	title_label.text = gig.title
	tag_label.text = gig.tag
	#
	#var image:Image = gig.visual.get_image()
	#image.resize(visual_size,visual_size)
	#
	#gig_visual.texture = ImageTexture.create_from_image(image)
	gig_visual.texture = gig.visual
	
func free_play() -> void:
	var menu_manager:MenuManager = get_tree().get_first_node_in_group("MenuManager")
	menu_manager.load_game_free_mode(gig.path_to_game_scn)
	close()

func select() -> void:
	on_selected.emit(self,gig)
	
func create_campaign() -> void:
	on_create_pressed.emit(self,gig)

func close() -> void:
	queue_free()
