extends Node
class_name MenuManager

@export var screen_manager:ScreenManager

@export var gig_selector:GigSelector
@export var gig_overview:GigOverview
@export var gig_pck_loader:GigLoaderPCK
@export var use_local_pck:bool=true

@export var music_library:Dictionary
@export var sfx_manager:SFXManager

# Called when the node enters the scene tree for the first time.

func _init() -> void:
	add_to_group("MenuManager")
	
func _ready() -> void:
	MusicManager.play_song(music_library["Menu"])
	gig_selector.on_gig_selected.connect(handle_gig_selection)
	
#	this will trigger if coming back from a gig into menu. active gig should be non-null and so remove all its singletons
	var current_gig:ClubhouseGig = SceneManager.get_interscene_data("CurrentGig")
	if current_gig != null:
		var config_file = FileAccess.open(current_gig.get_config_path(), FileAccess.READ)
		if config_file:
			var config = JSON.parse_string(config_file.get_as_text())
			config_file.close()
			unregister_singletons(config)
		SceneManager.interscene_data.erase("CurrentGig")
	
	if SolanaService.wallet.is_logged_in():
		handle_user_login()
	else:
		SolanaService.wallet.on_login_success.connect(handle_user_login)
		
func handle_user_login() -> void:
	pass
	
func play_ui_sound(sound_name:String) -> void:
	sfx_manager.play_sound(sound_name)
	
	
func handle_gig_selection(selected_gig:ClubhouseGig) -> void:
	screen_manager.switch_active_panel(1)
	gig_overview.setup_gig(selected_gig)
	
	
func load_gig(campaign_key:Pubkey,campaign_data:Dictionary,player_data:Dictionary) -> void:
	play_ui_sound("ButtonSimple")
	var scene_to_load = await try_load_pck_scene()

	if scene_to_load!=null:
		SceneManager.load_scene(scene_to_load,true,-1,0.8,{
			"FreePlay":false,
			"CampaignKey":campaign_key,
			"CampaignData":campaign_data,
			"PlayerData":player_data,
			"CurrentGig": gig_overview.active_gig
			},false,false)
		MusicManager.stop_song(1.0)
		
func load_gig_free_mode() -> void:
	play_ui_sound("ButtonSimple")
	var scene_to_load = await try_load_pck_scene()
	
	if scene_to_load!=null:
		SceneManager.load_scene(scene_to_load,true,-1,0.0,{"FreePlay":true},false,false)
		MusicManager.stop_song(1.0)
		
func try_load_pck_scene():
	var success:bool = await gig_pck_loader.load_gig(gig_overview.active_gig,use_local_pck)
	if !success:
		push_error("Failed to load gig, please try again!")
		return null
	
	var config_file = FileAccess.open(gig_overview.active_gig.get_config_path(), FileAccess.READ)
	if config_file:
		var config:Dictionary = JSON.parse_string(config_file.get_as_text())
		config_file.close()
		register_singletons(config)
	else:
		print("Failed to load config file")
		return null
		
	return gig_overview.active_gig.get_scene_path()
	
func register_singletons(gig_config:Dictionary) -> void:
	if not gig_config.has("autoloads"):
		print("Autoloads not found in the gig config")
		return
		
	for autoload in gig_config.autoloads:
		var resource = ResourceLoader.load(autoload["path"])
		if resource is GDScript:
			print(resource)
			var node = Node.new()
			node.set_script(resource)
			node.name = autoload["name"]
			get_tree().root.add_child(node)
			Engine.register_singleton(node.name,node)
			print(Engine.get_singleton_list())
			print("Autoload registered: ", autoload["name"])
		elif resource is PackedScene:
			var node = resource.instantiate()
			node.name = autoload["name"]
			get_tree().root.add_child(node)
			Engine.register_singleton(node.name,node)
			print("Autoload registered: ", autoload["name"])
		else:
			print("Failed to load autoload: ", autoload.path)
			return
			
func unregister_singletons(gig_config: Dictionary) -> void:
	if not gig_config.has("autoloads"):
		print("Autoloads not found in the gig config")
		return

	for autoload in gig_config.autoloads:
		var singleton_name = autoload["name"]
		var singleton = Engine.get_singleton(singleton_name)
		
		if singleton:
			Engine.unregister_singleton(singleton_name)
			get_tree().root.remove_child(singleton)
			singleton.queue_free()
			print("Autoload unregistered: ", singleton_name)
		else:
			print("Singleton not found: ", singleton_name)
