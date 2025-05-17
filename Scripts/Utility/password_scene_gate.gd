extends Node
class_name PasswordSceneGate

@export var path_to_scene:String
@export var password_lock:PasswordLock

func _ready() -> void:
	if OS.has_feature("editor"):
		load_scene()
	else:
		password_lock.on_password_unlocked.connect(load_scene)
	
func load_scene() -> void:
	SceneManager.load_scene(path_to_scene,true,-1,0.0)
