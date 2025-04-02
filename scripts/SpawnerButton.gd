# SpawnerButton.gd - Button that spawns objects
extends StaticBody3D
class_name SpawnerButton

@export var interact_text: String = "Press F to activate"
@export var scene_to_spawn: PackedScene 
@export var spawn_point: Node3D
@export var cooldown_time: float = 1.0  # Time between button presses

# Internal state
var can_press: bool = true

func _ready() -> void:
	# Ensure we have necessary exports
	if not scene_to_spawn:
		push_warning("SpawnerButton missing scene_to_spawn property")
	if not spawn_point:
		push_warning("SpawnerButton missing spawn_point property")

# Handle player interaction
func interact(player: Node = null) -> void:
	if not can_press:
		return
	
	if not scene_to_spawn or not spawn_point:
		print("Missing scene or spawn point")
		return
	
	# Create cooldown
	can_press = false
	get_tree().create_timer(cooldown_time).timeout.connect(func(): can_press = true)
	
	# Spawn the object
	var spawned = scene_to_spawn.instantiate()
	
	# Set position and add to scene
	spawned.global_transform = spawn_point.global_transform
	get_tree().current_scene.add_child(spawned)
	
	# Apply small impulse if it's a physics object
	if spawned is RigidBody3D:
		# Wait a frame to make sure physics is initialized
		get_tree().create_timer(0.1).timeout.connect(
			func(): 
				if is_instance_valid(spawned):
					spawned.apply_impulse(Vector3(0, 0.5, 0))
		)
	
	# Provide feedback
	print("BUTTON is pressed: Spawned " + spawned.name)
	
	# Visual feedback (optional - implement if you have a mesh)
	var button_mesh = get_node_or_null("MeshInstance3D")
	if button_mesh:
		var original_y = button_mesh.position.y
		# Quick animation to push button down and up
		var tween = create_tween()
		tween.tween_property(button_mesh, "position:y", original_y - 0.02, 0.1)
		tween.tween_property(button_mesh, "position:y", original_y, 0.1)
