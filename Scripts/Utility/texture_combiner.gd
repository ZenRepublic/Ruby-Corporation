extends Node
class_name TextureCombiner

var base_visual:TextureRect
var base_image:Image
var layers:Dictionary

var image_size:Vector2 = Vector2(512,512)
var scaling_factor:Vector2

func _init(base:TextureRect, desired_size:Vector2=Vector2(512,512)) -> void:
	image_size = desired_size
	
	base_visual = base
	base_image = base_visual.texture.get_image()
	if base_image.is_compressed():
		base_image.decompress()
	base_image.convert(Image.FORMAT_RGBA8)
	scaling_factor = image_size/base_visual.get_size()
	base_image.resize(image_size.x,image_size.y)
	
func add_visual_layer(visual:TextureRect) -> void:
	var image:Image = visual.texture.get_image()
	var image_dimensions:Vector2 = visual.get_size()*scaling_factor
	
	add_layer(image,image_dimensions,get_relative_pos(visual.global_position))
	
func add_label_layer(label:Label) -> void:
	var viewport = SubViewport.new()
	add_child(viewport)
	viewport.size = label.get_rect().size
	viewport.transparent_bg=true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var dummy_label:Label = label.duplicate()
	viewport.add_child(dummy_label)
	
#	for some reason need to wait 2 frames
	await get_tree().process_frame
	await get_tree().process_frame
	var image:Image = viewport.get_texture().get_image()
	var image_dimensions:Vector2 = Vector2(viewport.size.x*scaling_factor.x,viewport.size.y*scaling_factor.y)

	add_layer(image,image_dimensions,get_relative_pos(label.global_position))
	
	viewport.queue_free()
	pass
	
func add_layer(image:Image,size:Vector2,position:Vector2) -> void:
	var layer_index:int = layers.keys().size()
	var layer = {
		"image":image,
		"size":size,
		"position":position
	}
	layers[layer_index] = layer
	pass

func get_combined_image() -> Image:
	var combined_image:Image = base_image
	
	for key in layers.keys():
		var layer = layers[key]
		var formatted_layer:Image = layer["image"]
		if formatted_layer.is_compressed():
			formatted_layer.decompress()
		formatted_layer.resize(layer["size"].x,layer["size"].y)
		formatted_layer.convert(Image.FORMAT_RGBA8)
		
		for x in range(layer["size"].x):
			for y in range(layer["size"].y):
				var layer_pixel:Color = layer["image"].get_pixel(x, y)
				var pos_in_image:Vector2 = layer["position"]+Vector2(x,y)
				if is_in_bounds(combined_image,pos_in_image):
					var base_pixel = combined_image.get_pixel(pos_in_image.x, pos_in_image.y)
					# Set the blended pixel back to the base image
					base_image.set_pixel(pos_in_image.x, pos_in_image.y, blend_pixels(base_pixel,layer_pixel))
	
		
	combined_image.save_png("res://test.png")
	return combined_image
	
func is_in_bounds(image:Image,position:Vector2) -> bool:
	return position.x >= 0 and position.x < image.get_width() and position.y >= 0 and position.y < image.get_height()
	
func blend_pixels(base_pixel:Color,layer_pixel:Color) -> Color:
	if layer_pixel.a == 0:
		return base_pixel
	# Alpha compositing formula
	var blended_alpha = layer_pixel.a + base_pixel.a * (1 - layer_pixel.a)
	var blended_color = layer_pixel * layer_pixel.a + base_pixel * base_pixel.a * (1 - layer_pixel.a)

	# Avoid division by zero for fully transparent outputs
	if blended_alpha > 0:
		blended_color /= blended_alpha
		
	return Color(blended_color.r, blended_color.g, blended_color.b, blended_alpha)
	
func get_relative_pos(layer_global_pos:Vector2) -> Vector2:
	var offset_from_base:Vector2 = layer_global_pos - base_visual.global_position
	var relative_local_pos:Vector2 = base_visual.get_global_transform().basis_xform_inv(offset_from_base)
	relative_local_pos*=scaling_factor
	
	return relative_local_pos
