# TrayStorage.gd - A specialized storage container that works as a tray
extends StorageObject
class_name TrayStorage

@export var item_height: float = 0.05  # Height of items above tray surface

func _ready() -> void:
	super._ready()
	
	# Override default texts for the tray
	interact_text = "Press F to pick up tray"
	use_text = "Press E to collect with tray"
	
	# Initialize with flat grid arrangement
	arrangement_type = ArrangementType.GRID

# Override to optimize for tray-specific behavior
func collect_item(target_item: Node3D, player: Node) -> bool:
	if not is_instance_valid(target_item) or not (target_item is PickableObject):
		print("Target is not a valid pickable item")
		return false
	
	print("Tray collecting: ", target_item.name)
	
	# Try to store the item
	var success = store_item(target_item)
	if success:
		# Provide feedback - could add visual or sound effect here
		print("Item added to tray")
	
	return success

# Override to position items at the correct height on the tray surface
func store_item(item: Node3D, player = null) -> bool:
	var success = super.store_item(item, player)
	
	if success and is_instance_valid(item):
		# Adjust item height to sit on tray surface
		# This is useful for items that might have different pivot points
		var current_pos = item.position
		
		# Get the height of the item if it has a collision shape
		var collision_shape = item.get_node_or_null("CollisionShape3D")
		var item_extent_y = 0.0
		
		if collision_shape and collision_shape.shape:
			if collision_shape.shape is BoxShape3D:
				item_extent_y = collision_shape.shape.size.y / 2
			elif collision_shape.shape is SphereShape3D:
				item_extent_y = collision_shape.shape.radius
			elif collision_shape.shape is CapsuleShape3D:
				item_extent_y = collision_shape.shape.height / 2
		
		# If we couldn't determine height, use a default value
		if item_extent_y == 0.0:
			item_extent_y = item_size.y / 2
		
		# Adjust position to sit properly on tray
		item.position.y = item_height + item_extent_y
	
	return success

# Override to make the visualization show up by default in game
func _get_storage_visualizer() -> Node:
	var visualizer = get_node_or_null("DebugVisualizer")
	
	# If no visualizer exists, create one
	if not visualizer:
		visualizer = StorageVisualizer.new()
		visualizer.name = "DebugVisualizer"
		visualizer.debug_in_game = true
		add_child(visualizer)
	
	return visualizer
