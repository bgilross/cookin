## Utility script for handling visible storage behavior
## Used for containers that visibly display their contents
extends Node

# Define storage types for different arrangement logics
enum StorageArrangement {
	STACK,      # Items stack on top of each other
	GRID,       # Items arrange in a grid pattern
	HANGING,    # Items hang from points (like hooks)
	FREEFORM    # Items can be placed anywhere within bounds
}

# Container for info about a storage slot
class StorageSlot:
	var position: Vector3
	var rotation: Vector3
	var size: Vector3
	var occupied: bool = false
	var stored_item: Node3D = null
	
	func _init(pos: Vector3, rot: Vector3 = Vector3.ZERO, sz: Vector3 = Vector3(0.1, 0.1, 0.1)):
		position = pos
		rotation = rot
		size = sz

# Get storage area dimensions from a collision shape
static func get_storage_area_size(storage_area: Area3D) -> Vector3:
	if not storage_area:
		print("Error: No storage area provided")
		return Vector3.ONE
	
	var collision_shape = storage_area.get_node_or_null("CollisionShape3D")
	if not collision_shape:
		print("Error: Storage area has no CollisionShape3D child")
		return Vector3.ONE
		
	var shape = collision_shape.shape
	if not shape:
		print("Error: CollisionShape3D has no shape")
		return Vector3.ONE
	
	# Get dimensions based on shape type
	var size = Vector3.ONE
	
	if shape is BoxShape3D:
		size = shape.size
	elif shape is SphereShape3D:
		var radius = shape.radius
		size = Vector3(radius * 2, radius * 2, radius * 2)
	elif shape is CapsuleShape3D:
		var radius = shape.radius
		var height = shape.height
		size = Vector3(radius * 2, height, radius * 2)
	elif shape is CylinderShape3D:
		var radius = shape.radius
		var height = shape.height
		size = Vector3(radius * 2, height, radius * 2)
	else:
		print("Warning: Unsupported collision shape type, using default size")
	
	# Apply the transform scale to the size
	size *= collision_shape.transform.basis.get_scale()
	
	return size

# Get all valid storage slots based on storage area and arrangement type
static func calculate_storage_slots_from_area(
	storage_area: Area3D, 
	arrangement: int, 
	item_size: Vector3 = Vector3(0.1, 0.1, 0.1),
	padding: float = 0.05
) -> Array[StorageSlot]:
	var container_size = get_storage_area_size(storage_area)
	return calculate_storage_slots(container_size, arrangement, item_size, padding)

# Get all valid storage slots based on container size and arrangement type
static func calculate_storage_slots(
	container_size: Vector3, 
	arrangement: int, 
	item_size: Vector3 = Vector3(0.1, 0.1, 0.1),
	padding: float = 0.05
) -> Array[StorageSlot]:
	var slots: Array[StorageSlot] = []
	
	match arrangement:
		StorageArrangement.STACK:
			# For stacking, we create slots that stack vertically
			var slot_pos = Vector3(0, item_size.y / 2, 0)
			var max_items = int(container_size.y / (item_size.y + padding))
			
			for i in range(max_items):
				var slot = StorageSlot.new(slot_pos)
				slots.append(slot)
				slot_pos.y += item_size.y + padding
		
		StorageArrangement.GRID:
			
			# For grid, we create a 2D array of positions
			print("Starting GRID")
			var width_slots = int(container_size.x / (item_size.x + padding))
			var depth_slots = int(container_size.z / (item_size.z + padding))
			print("Width Slots = ", width_slots)
			print("Height Slots = ", depth_slots)
			
			var start_x = -container_size.x / 2 + item_size.x / 2
			var start_z = -container_size.z / 2 + item_size.z / 2
			
			for x in range(width_slots):
				for z in range(depth_slots):
					var pos_x = start_x + x * (item_size.x + padding)
					var pos_z = start_z + z * (item_size.z + padding)
					var slot = StorageSlot.new(Vector3(pos_x, item_size.y / 2, pos_z))
					slots.append(slot)
		
		StorageArrangement.HANGING:
			# For hanging, we create a row of hanging points
			var width_slots = int(container_size.x / (item_size.x + padding))
			var hang_height = container_size.y - item_size.y / 2
			
			var start_x = -container_size.x / 2 + item_size.x / 2
			
			for x in range(width_slots):
				var pos_x = start_x + x * (item_size.x + padding)
				var slot = StorageSlot.new(Vector3(pos_x, hang_height, 0))
				slots.append(slot)
		
		StorageArrangement.FREEFORM:
			# For freeform, we just create a single slot in the center
			# (freeform would typically be handled differently with custom positioning)
			var slot = StorageSlot.new(Vector3(0, item_size.y / 2, 0))
			slots.append(slot)
	
	return slots

# Add an item to a storage container
static func add_item_to_storage(
	storage_node: Node3D, 
	item: Node3D, 
	slots: Array[StorageSlot]
) -> bool:
	# Find first available slot
	var target_slot = null
	for slot in slots:
		if not slot.occupied:
			target_slot = slot
			break
	
	if target_slot == null:
		print("Storage full, no available slots")
		return false
	
	# Remove item from its current parent
	if item.get_parent():
		var global_transform = item.global_transform
		item.get_parent().remove_child(item)
		item.global_transform = global_transform
	
	# Add item to storage container
	storage_node.add_child(item)
	
	# Position item in slot
	item.position = target_slot.position
	item.rotation = target_slot.rotation
	
	# Mark slot as occupied
	target_slot.occupied = true
	target_slot.stored_item = item
	
	# Store reference to slot in item if it has the property
	if item.get("storage_slot") != null:
		item.storage_slot = target_slot
	
	return true

# Remove an item from storage
static func remove_item_from_storage(
	item: Node3D, 
	slots: Array[StorageSlot]
) -> Node3D:
	# Find which slot has this item
	var target_slot = null
	for slot in slots:
		if slot.stored_item == item:
			target_slot = slot
			break
	
	if target_slot == null:
		print("Item not found in storage")
		return null
	
	# Mark slot as unoccupied
	target_slot.occupied = false
	target_slot.stored_item = null
	
	# Remove item from storage container
	if item.get_parent():
		var global_transform = item.global_transform
		item.get_parent().remove_child(item)
		item.global_transform = global_transform
	
	return item

# Calculate weight/volume capacity based on stored items
static func calculate_storage_usage(slots: Array[StorageSlot]) -> Dictionary:
	var result = {
		"used_slots": 0,
		"total_slots": slots.size(),
		"percentage_full": 0.0
	}
	
	for slot in slots:
		if slot.occupied:
			result.used_slots += 1
	
	if result.total_slots > 0:
		result.percentage_full = float(result.used_slots) / float(result.total_slots) * 100.0
	
	return result

# Visualize storage slots for debugging using modern Godot 4.x drawing
# This should be called from _process or other appropriate function
static func debug_draw_slots(storage_node: Node3D, slots: Array[StorageSlot]):
	# This function requires the calling class to extend Node3D and implement _draw()
	# Which will call this function
	
	for slot in slots:
		var slot_pos = slot.position
		var size = slot.size / 2
		
		# Set color based on whether slot is occupied
		var color = Color(1, 0, 0, 0.5) if slot.occupied else Color(0, 1, 0, 0.5)
		
		# Draw cube wireframe in 3D
		var lines = []
		
		# Define the 8 corners of the cube
		var corners = []
		for i in range(8):
			var x = slot_pos.x + (size.x if i & 1 else -size.x)
			var y = slot_pos.y + (size.y if i & 2 else -size.y)
			var z = slot_pos.z + (size.z if i & 4 else -size.z)
			corners.append(Vector3(x, y, z))
		
		# Connect corners with lines (12 edges of a cube)
		var edges = [
			[0, 1], [1, 3], [3, 2], [2, 0],  # Bottom face
			[4, 5], [5, 7], [7, 6], [6, 4],  # Top face
			[0, 4], [1, 5], [2, 6], [3, 7]   # Connecting edges
		]
		
		for edge in edges:
			lines.append([corners[edge[0]], corners[edge[1]], color])
		
		# Return the lines data so the caller can use it in _draw
		return lines

# Example of how to use this in a storage container class:
# func _draw():
#     if Engine.is_editor_hint() or debug_mode:
#         var lines = VisibleStorageUtils.debug_draw_slots(self, storage_slots)
#         for line in lines:
#             draw_line_3d(line[0], line[1], line[2])
