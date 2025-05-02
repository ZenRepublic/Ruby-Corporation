extends Camera2D
class_name PlayerCamera

@export var light_source:Light2D
@export var min_light_strength:float
@export var max_light_strength:float
@export var light_radius:float = 5

@export var min_zoom:float = 0.6
@export var max_zoom:float = 3.0

@export var move_speed:float

@export var shake_strength: float = 20.0
@export var shake_duration: float = 0.5
@export var shake_frequency: float = 20.0

var zoom_tick = max_zoom / 20

var shake_timer: float = 0.0
var original_position: Vector2
var time_since_last_shake: float = 0.0

var player:PlayerManager

signal on_camera_zoom(amount:float)
# Called when the node enters the scene tree for the first time.
func _ready():
	zoom = Vector2(min_zoom,min_zoom)
	player = get_parent()
	
var prev_surrounding_tiles:Array[MineTile]
func _process(delta):
	var surrounding_tiles:Array[MineTile] = player.get_surrounding_tiles()
	for tile in prev_surrounding_tiles:
		if tile not in surrounding_tiles:
			tile.set_brightness(0)
			
	for tile in surrounding_tiles:
		var distance:float = tile.pos_in_grid.distance_to(player.get_closest_tile().pos_in_grid)
		tile.set_brightness(get_zoom_strength()*(1-(distance/light_radius)))
		
	prev_surrounding_tiles = surrounding_tiles
	
	if shake_timer > 0:
		shake_timer -= delta
		time_since_last_shake += delta

		# Only update the position based on the frequency
		if time_since_last_shake >= 1.0 / shake_frequency:
			time_since_last_shake = 0.0

			# Calculate a random offset
			var offset_x = (randf() * 2 - 1) * shake_strength
			var offset_y = (randf() * 2 - 1) * shake_strength
			position = original_position + Vector2(offset_x, offset_y)

		# Stop the shake if the timer has expired
		if shake_timer <= 0:
			position = original_position
		
# Function to start the screen shake
func start_shake(duration: float = -1.0, strength: float = -1.0, frequency: float = -1.0):
	if duration > 0:
		shake_duration = duration
	if strength > 0:
		shake_strength = strength
	if frequency > 0:
		shake_frequency = frequency
	shake_timer = shake_duration
	time_since_last_shake = 0.0
	original_position = position
	
func zoom_camera(zoom_factor:float) -> void:
	var curr_zoom = zoom.x
	var old_zoom = curr_zoom
	curr_zoom *= zoom_factor
	curr_zoom = clamp(curr_zoom,min_zoom,max_zoom)
		
	zoom = Vector2(curr_zoom,curr_zoom)
	if curr_zoom!=old_zoom:
		on_camera_zoom.emit(get_normalized_zoom(curr_zoom))
		
	adjust_light()
		
#func focus_camera(zoom_strength:float,speed:float) -> void:
	#var start_zoom:float = curr_zoom
	#while get_normalized_zoom(curr_zoom) != zoom_strength:
		#curr_zoom = move_toward(curr_zoom,zoom_strength,speed)
		#await get_tree().process_frame
		
func set_zoom_strength(zoom_strength:float) -> void:
	var curr_zoom = lerpf(min_zoom,max_zoom,zoom_strength)
	zoom = Vector2(curr_zoom,curr_zoom)
	

func get_normalized_zoom(zoom_level:float) -> float:
	return (zoom_level - min_zoom) / (max_zoom - min_zoom)
	
func get_zoom_strength() -> float:
	return (zoom.x - min_zoom) / (max_zoom - min_zoom)
	
func adjust_light() -> void:
	light_source.texture_scale = 1-get_zoom_strength()
	light_source.texture_scale = clamp(light_source.texture_scale,0.3,1)
	light_source.energy = lerp(min_light_strength,max_light_strength,get_zoom_strength())

func get_adjusted_bounds(map_bounds:Rect2) -> Rect2:
	var screen_size:Vector2 = get_viewport().size 
	var half_screen_size = (screen_size * zoom) / 2

	# Calculate visible area boundaries
	var visible_bounds = Rect2(
		self.global_position - half_screen_size,
		screen_size * zoom
	)

	# Clamp visible bounds to the map bounds
	var clamped_position = visible_bounds.position.clamp(map_bounds.position, map_bounds.position + map_bounds.size - visible_bounds.size)
	return Rect2(clamped_position, visible_bounds.size)
