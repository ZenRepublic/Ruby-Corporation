extends Node
class_name GigDisplay

@export var title_label:Label
@export var tag_label:Label
@export var description_label:Label

@export var gig_visual:TextureRect
@export var visual_size:int = 512

@export var select_button:BaseButton

var gig:ClubhouseGig

signal on_selected(selected_gig:ClubhouseGig)

func _ready() -> void:
	if select_button!=null:
		select_button.pressed.connect(select_gig)

func setup_display(gig:ClubhouseGig) -> void:
	self.gig = gig
	set_basic_fields(gig)
	
	if description_label!=null:
		description_label.text = gig.description
	
	
func set_basic_fields(gig:ClubhouseGig) -> void:
	title_label.text = gig.title
	tag_label.text = gig.tag
	#
	#var image:Image = gig.visual.get_image()
	#image.resize(visual_size,visual_size)
	#
	#gig_visual.texture = ImageTexture.create_from_image(image)
	gig_visual.texture = gig.visual
	
func select_gig() -> void:
	on_selected.emit(gig)
