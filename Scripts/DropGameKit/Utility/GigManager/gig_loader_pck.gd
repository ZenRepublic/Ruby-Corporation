extends Node
class_name GigLoaderPCK

@export var gigs_storage_dir:String = "user://Gigs/"

var curr_gig:ClubhouseGig

func _ready():
	var dir = DirAccess.open("user://")
	if dir:
		# Remove "user://" prefix for dir_exists check, as dir is already in user://
		var relative_path = gigs_storage_dir.replace("user://", "").strip_edges(true, false)
		if not dir.dir_exists(relative_path):
			var err = dir.make_dir_recursive(relative_path)
			if err == OK:
				print("Created folder: ", gigs_storage_dir)
			else:
				print("Failed to create folder ", gigs_storage_dir, ": Error ", err)
	else:
		print("Failed to access user:// directory")

	
# Main entry
func load_gig(gig:ClubhouseGig, local: bool) -> bool:
	curr_gig = gig
	var scene:PackedScene
	var path_to_pck:String = gig.get_url_or_path(local)
	
	var split_path:Array = path_to_pck.split("/")
	var new_gig_name:String = split_path[split_path.size()-1]
	var gig_info:Dictionary = extract_name_and_version(new_gig_name)
	if gig_info["base_name"] == "":
		push_error("❌ PCK FILE NOT FOUND, FAILED TO LOAD GIG!")
		return false
		
	var existing_gig_name:String = find_existing_gig(gigs_storage_dir,gig_info["base_name"])
	if existing_gig_name!="":
		var existing_gig_info:Dictionary = extract_name_and_version(existing_gig_name)
		if existing_gig_info["version"] != gig_info["version"]:
			var delete_success:bool = delete_file(gigs_storage_dir,existing_gig_name)
			if !delete_success:
				push_error("❌ Failed to delete older gig version")
				return false
	
	var file_location = gigs_storage_dir + new_gig_name
	if !FileAccess.file_exists(file_location):
		if local:
			print("📦 Loading local PCK from: ", path_to_pck)
			copy_file(path_to_pck, file_location)
		else:
			print("🌐 Downloading remote PCK from: ", path_to_pck)
			await load_gig_remote(path_to_pck,file_location)
	
	var success:bool = ProjectSettings.load_resource_pack(file_location)
	if !success:
		push_error("❌ Failed to load Gig PCK file")
		return false
	
	print("✅ Gig loaded successfully")
	return true
	
	
# -- REMOTE PCK LOADING --
func load_gig_remote(url: String, file_location:String) -> void:
	var custom_headers = [
		"Accept: application/octet-stream",
	]
	var response:Dictionary = await HttpRequestHandler.send_get_request(url,false,custom_headers)
	if response.has("error"):
		return
		
	var file = FileAccess.open(file_location, FileAccess.WRITE)
	file.store_buffer(response["body"])
	file.close()
	
func extract_name_and_version(path: String) -> Dictionary:
	var regex = RegEx.new()
	regex.compile("(.*)_v([0-9.]+)\\.pck$")
	var result = regex.search(path)
	if result:
		return {
			"base_name": result.get_string(1), # e.g., "launching_soon"
			"version": result.get_string(2) # e.g., "0.1", "0.2"
		}
	return {
		"base_name": "",
		"version": "0.0"
	}
	
func find_existing_gig(directory:String, base_name: String) -> String:
	var dir = DirAccess.open(directory)
	if dir:
		dir.list_dir_begin() # Start listing directory contents
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".pck"):
				var file_info = extract_name_and_version(file_name)
				if file_info["base_name"] == base_name:
					dir.list_dir_end() # Close the directory
					return file_name
			file_name = dir.get_next()
		dir.list_dir_end() # Ensure directory is closed
	return ""
	
func copy_file(source_path: String, dest_path: String) -> bool:
	var source = FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		push_error("Failed to open source file: " + source_path)
		return false

	var dest = FileAccess.open(dest_path, FileAccess.WRITE)
	if dest == null:
		push_error("Failed to open destination file: " + dest_path)
		return false

	var buffer:PackedByteArray = source.get_buffer(source.get_length())
	dest.store_buffer(buffer)
	source.close()
	dest.close()
	return true
	
func delete_file(directory:String, file_name:String) -> bool:
	# Use DirAccess to delete the file
	var dir = DirAccess.open(directory)
	if dir:
		var error = dir.remove(file_name)
		if error == OK:
			print("✅ Successfully deleted PCK file: " + file_name)
			return true
		else:
			push_error("❌ Failed to delete PCK file: " + file_name + " (Error: " + str(error) + ")")
			return false
	else:
		push_error("❌ Failed to access user:// directory")
		return false
		
