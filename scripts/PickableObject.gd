# PickableObject.gd - Base class for any object that can be picked up
extends RigidBody3D
class_name PickableObject

@export var interact_text: String = "Press F to pick up"
@export var weight: float = 1.0

# Signal emitted when object is picked up
signal picked_up(by_player)
# Signal emitted when object is dropped
signal dropped(at_position)

# Original physics properties to restore when dropped
var _original_collision_layer: int
var _original_collision_mask: int
var _original_freeze_mode: int

func _ready() -> void:
	# Store original physics properties
	_original_collision_layer = collision_layer
	_original_collision_mask = collision_mask
	_original_freeze_mode = freeze_mode

# Called when player presses F on this object
func interact(player: Node) -> void:
	pickup(player)

# Called to pick up this object
func pickup(player: Node) -> void:
	if not player.has_method("hold_item"):
		return
	
	# Freeze physics while held
	freeze_physics()
	
	# Detach from current parent
	var current_parent = get_parent()
	if current_parent:
		current_parent.remove_child(self)
	
	# Let the player hold this item
	player.hold_item(self)
	
	# Reset transform relative to hold position
	transform = Transform3D.IDENTITY
	
	# Emit signal
	picked_up.emit(player)

# Freeze physics while held
func freeze_physics() -> void:
	# Freeze rigid body
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	
	# Disable collisions while held
	collision_layer = 0
	collision_mask = 0
	
	# Disable shape if needed
	var shape = get_node_or_null("CollisionShape3D")
	if shape:
		shape.disabled = true

# Restore physics when dropped
func unfreeze_physics() -> void:
	# Restore original properties
	collision_layer = _original_collision_layer
	collision_mask = _original_collision_mask
	freeze_mode = _original_freeze_mode
	
	# Unfreeze and wake up
	freeze = false
	sleeping = false
	
	# Re-enable collision shape
	var shape = get_node_or_null("CollisionShape3D")
	if shape:
		shape.disabled = false

# Called when the object is dropped
func on_dropped(drop_transform: Transform3D) -> void:
	# Add to scene at the drop position
	var tree = Engine.get_main_loop()
	if not tree:
		print("Error: Can't get SceneTree")
		return
		
	var scene_root = tree.root
	if not scene_root:
		print("Error: SceneTree root is null")
		return
		
	# Find the correct level node
	var level_node = scene_root.get_node_or_null("Level") # Adjust path
	if not level_node:
		level_node = scene_root # Fallback to root
	
	# Add to scene
	level_node.add_child(self)
	
	# Set transform
	global_transform = drop_transform
	
	# Restore physics
	unfreeze_physics()
	
	# Add small impulse to prevent sticking
	apply_impulse(Vector3(0, -0.1, 0))
	
	# Emit signal
	dropped.emit(global_position)
