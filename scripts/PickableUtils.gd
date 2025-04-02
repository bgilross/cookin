## Utility script for handling common pickable item behavior
## Used by both RigidBody3D-based and Node3D-based pickables
extends Node

# Static dictionaries to store original object properties
static var _original_collision_layer = {}
static var _original_collision_mask = {}
static var _original_freeze_mode = {}

static func freeze_physics(obj: Node3D) -> void:
	if obj is RigidBody3D:
		# Store original values
		var id = obj.get_instance_id()
		_original_collision_layer[id] = obj.collision_layer
		_original_collision_mask[id] = obj.collision_mask
		_original_freeze_mode[id] = obj.freeze_mode
		
		# Freeze physics
		obj.freeze = true
		obj.linear_velocity = Vector3.ZERO
		obj.angular_velocity = Vector3.ZERO
		obj.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		
		# Disable collisions while held
		obj.collision_layer = 0
		obj.collision_mask = 0
		
		# Disable shape if needed
		var shape = obj.get_node_or_null("CollisionShape3D")
		if shape:
			shape.disabled = true

static func unfreeze_physics(obj: Node3D) -> void:
	if obj is RigidBody3D:
		# Restore original collision settings if available
		var id = obj.get_instance_id()
		if _original_collision_layer.has(id):
			obj.collision_layer = _original_collision_layer[id]
			_original_collision_layer.erase(id)
		if _original_collision_mask.has(id):
			obj.collision_mask = _original_collision_mask[id]
			_original_collision_mask.erase(id)
		if _original_freeze_mode.has(id):
			obj.freeze_mode = _original_freeze_mode[id]
			_original_freeze_mode.erase(id)
		else:
			obj.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		
		# Unfreeze
		obj.freeze = false
		obj.sleeping = false
		
		# Re-enable collision shape
		var shape = obj.get_node_or_null("CollisionShape3D")
		if shape:
			shape.disabled = false

static func pickup(obj: Node3D, player: Node) -> void:
	if not player.has_method("hold_item"):
		return
	
	freeze_physics(obj)
	
	if obj.get_parent():
		obj.get_parent().remove_child(obj)
	
	player.hold_item(obj)
	obj.transform = Transform3D.IDENTITY

static func calculate_drop_position(player: Node) -> Transform3D:
	# Assuming player has a Camera3D node that we can use for direction
	var camera = player.get_node_or_null("Camera3D")
	if not camera:
		print("[Drop] Warning: Player has no Camera3D node, using player transform instead")
		return player.global_transform
	
	# Calculate drop position in front of the camera
	var drop_position = camera.global_position + (-camera.global_transform.basis.z * 1.5)
	
	# Create a transform with the original object's orientation but at the new position
	return Transform3D(Basis(), drop_position)

static func drop_from_player(obj: Node3D, player: Node) -> void:
	if not is_instance_valid(obj):
		print("[Drop] Error: Object is no longer valid.")
		return
	
	# Calculate where to drop the object
	var drop_transform = calculate_drop_position(player)
	
	# Execute the actual drop
	drop(obj, drop_transform)

static func drop(obj: Node3D, drop_transform: Transform3D) -> void:
	if not is_instance_valid(obj):
		print("[Drop] Error: Object is no longer valid.")
		return
		
	# Remove from parent first
	var parent = obj.get_parent()
	if parent:
		parent.remove_child(obj)
	
	# Find the correct level node instead of using scene root
	var tree = Engine.get_main_loop()
	if not tree:
		print("[Drop] Error: Can't get SceneTree - Engine.get_main_loop() returned null")
		return
		
	var scene_root = tree.root
	if not scene_root:
		print("[Drop] Error: SceneTree root is null")
		return
		
	var level_node = scene_root.get_node_or_null("Level") # Adjust path to your level node
	if not level_node:
		level_node = scene_root # Fallback to root
	
	# Add to level before setting transform
	level_node.add_child(obj)
	
	# Set transform after adding to scene
	obj.global_transform = drop_transform
	
	# Ensure physics are properly unfrozen
	unfreeze_physics(obj)
	
	# Add small impulse to prevent sticking
	if obj is RigidBody3D:
		# Small downward impulse
		obj.apply_impulse(Vector3(0, -0.1, 0))
		
	print("Dropped at:", drop_transform.origin)
