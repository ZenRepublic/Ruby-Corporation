extends Node
class_name AppEntrance

@export var path_to_scene:String
@export var password_lock:PasswordLock
@export var ios_incompatible_overlay:Control

func _ready() -> void:
	if password_lock!=null:
		password_lock.visible=false
	if ios_incompatible_overlay!=null:
		ios_incompatible_overlay.visible=false
	
	if OS.has_feature("web_ios"):
		if ios_incompatible_overlay!=null:
			ios_incompatible_overlay.visible=true
		return
		
	if password_lock!=null:
		password_lock.visible=true
	
		if OS.has_feature("editor"):
			load_scene()
		else:
			password_lock.on_password_unlocked.connect(load_scene)
		return
		
	load_scene()

func load_scene() -> void:
	SceneManager.load_scene(path_to_scene,false,-1,0.0)
