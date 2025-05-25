extends CanvasLayer
class_name ParticleCache

@export var frames_to_process:int = 15

func cache_particles(particle_scenes:Array) -> void:
	for particle_scn in particle_scenes:
		var particle_instance:Node2D = particle_scn.instantiate()
		add_child(particle_instance)
		
		for child in particle_instance.get_children():
			if child is CPUParticles2D:
				var particle:CPUParticles2D = child as CPUParticles2D
				particle.emitting = true
			elif child is CPUParticles3D:
				var particle:CPUParticles3D = child as CPUParticles3D
				particle.emitting = true
		
		for i in range(frames_to_process):
			await get_tree().process_frame
			
		print("loaded: ",particle_instance.name)
		particle_instance.queue_free()
