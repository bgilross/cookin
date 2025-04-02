# StorageObject.gd - Base class for objects that can store items
extends PickableObject
class_name StorageObject

# Enum for storage arrangement types
enum ArrangementType {
	GRID,
	STACK,
	HANGING,
	FREEFORM
}

# Storage configuration
@export_group("Storage Properties")
@export var arrangement_type: ArrangementType = ArrangementType.GRID
@export var item_size: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var item_padding: float = 0.05
@export var max_items: int = 10

# Storage state
var storage_slots = []
var stored_items = []
var use_text

# Reference to storage area
@onready var storage_area = $StorageArea

# Signal when items are added/removed
signal item_stored(item)
signal item_removed(item)

func _ready() -> void:
	super._ready()
	
	# Ensure we have a storage area
	if not storage_area or not storage_area is Area3D:
		push_error("StorageObject requires a child node named 'StorageArea' with a CollisionShape3D")
		return
	
	# Create storage slots based on the storage area's dimensions
	calculate_storage_slots()
	
	# Connect signals for storage area
	storage_area.body_entered.connect(_on_storage_area_body_entered)
	storage_area.body_exited.connect(_on_storage_area_body_exited)
	
	# Override interaction text
	interact_text = "Press F to pick up container"
	use_text = "Press E to collect with container"

# Override the interact method from PickableObject
func interact(player: Node) -> void:
	# We want custom interaction logic for storage containers
	if player.held_object == null:
		# If player isn't holding anything, pick up the container
		pickup(player)

# Called when player uses another object on this storage container
func receive_use(player: Node, used_object: Node3D) -> void:
	# When an object is used on this container, try to store it
	if used_object is PickableObject:
		# Try to store the object
		var success = store_item(used_object, player)
		if success:
			# Clear from player's hand if storage was successful
			player.held_object = null

# Called when this storage container is used on another object
func use(player: Node) -> void:
	# When the container is used, try to collect what the player is looking at
	var target = player.current_target
	if target != null and target is PickableObject:
		collect_item(target, player)

# Calculate storage slots based on the storage area's dimensions
func calculate_storage_slots() -> void:
	# Get dimensions from collision shape
	var collision_shape = storage_area.get_node_or_null("CollisionShape3D")
	if not collision_shape or not collision_shape.shape:
		push_error("Storage area must have a CollisionShape3D with a shape")
		return
	
	var container_size = Vector3.ONE
	
	# Get size based on shape type
	if collision_shape.shape is BoxShape3D:
		container_size = collision_shape.shape.size
	elif collision_shape.shape is SphereShape3D:
		var radius = collision_shape.shape.radius
		container_size = Vector3(radius * 2, radius * 2, radius * 2)
	else:
		push_error("Unsupported collision shape type")
		return
	
	# Apply transform scale
	container_size *= collision_shape.transform.basis.get_scale()
	
	# Clear existing slots
	storage_slots.clear()
	
	# Create slots based on arrangement type
	match arrangement_type:
		ArrangementType.GRID:
			create_grid_slots(container_size)
		ArrangementType.STACK:
			create_stack_slots(container_size)
		ArrangementType.HANGING:
			create_hanging_slots(container_size)
		ArrangementType.FREEFORM:
			create_freeform_slot(container_size)

# Create grid-based storage slots
func create_grid_slots(container_size: Vector3) -> void:
	var width_slots = int(container_size.x / (item_size.x + item_padding))
	var depth_slots = int(container_size.z / (item_size.z + item_padding))
	
	# Ensure at least one slot
	width_slots = max(1, width_slots)
	depth_slots = max(1, depth_slots)
	
	var start_x = -container_size.x / 2 + item_size.x / 2 + item_padding
	var start_z = -container_size.z / 2 + item_size.z / 2 + item_padding
	
	for x in range(width_slots):
		for z in range(depth_slots):
			var pos_x = start_x + x * (item_size.x + item_padding)
			var pos_z = start_z + z * (item_size.z + item_padding)
			var slot = {
				"position": Vector3(pos_x, item_size.y / 2, pos_z),
				"rotation": Vector3.ZERO,
				"size": item_size,
				"occupied": false,
				"stored_item": null
			}
			storage_slots.append(slot)
	
	# Limit to max_items
	if storage_slots.size() > max_items:
		storage_slots = storage_slots.slice(0, max_items)
	
	print("Created ", storage_slots.size(), " storage slots for ", name)

# Create stacked storage slots
func create_stack_slots(container_size: Vector3) -> void:
	var slot_pos = Vector3(0, item_size.y / 2, 0)
	var max_stack = int(container_size.y / (item_size.y + item_padding))
	max_stack = min(max_stack, max_items)
	
	for i in range(max_stack):
		var slot = {
			"position": slot_pos,
			"rotation": Vector3.ZERO,
			"size": item_size,
			"occupied": false,
			"stored_item": null
		}
		storage_slots.append(slot)
		slot_pos.y += item_size.y + item_padding

# Create hanging storage slots
func create_hanging_slots(container_size: Vector3) -> void:
	var width_slots = int(container_size.x / (item_size.x + item_padding))
	width_slots = min(width_slots, max_items)
	
	var hang_height = container_size.y - item_size.y / 2
	var start_x = -container_size.x / 2 + item_size.x / 2
	
	for x in range(width_slots):
		var pos_x = start_x + x * (item_size.x + item_padding)
		var slot = {
			"position": Vector3(pos_x, hang_height, 0),
			"rotation": Vector3.ZERO,
			"size": item_size,
			"occupied": false,
			"stored_item": null
		}
		storage_slots.append(slot)

# Create a single freeform slot
func create_freeform_slot(container_size: Vector3) -> void:
	var slot = {
		"position": Vector3(0, item_size.y / 2, 0),
		"rotation": Vector3.ZERO,
		"size": container_size,
		"occupied": false,
		"stored_item": null
	}
	storage_slots.append(slot)

# Try to store an item in this container
func store_item(item: Node3D, player = null) -> bool:
	if not is_instance_valid(item):
		print("Invalid item reference")
		return false
	
	# Check if we have space
	if stored_items.size() >= storage_slots.size():
		print("Storage is full")
		return false
	
	print("Attempting to store item: ", item.name)
	
	# Find first available slot
	var target_slot = null
	for slot in storage_slots:
		if not slot.occupied:
			target_slot = slot
			break
	
	if not target_slot:
		print("No available slots")
		return false
	
	# Remove from current parent
	if item.get_parent():
		var item_global_transform = item.global_transform
		item.get_parent().remove_child(item)
		item.global_transform = item_global_transform
	
	# Add to this container
	add_child(item)
	
	# Position in slot
	item.position = target_slot.position
	item.rotation = target_slot.rotation
	
	# Mark as occupied
	target_slot.occupied = true
	target_slot.stored_item = item
	
	# Add to stored items
	stored_items.append(item)
	
	# Freeze physics if it's a rigid body
	if item is RigidBody3D:
		if item.has_method("freeze_physics"):
			item.freeze_physics()
		else:
			item.freeze = true
	
	# Emit signal
	item_stored.emit(item)
	
	print("Item stored successfully")
	return true

# Remove an item from storage
func remove_item(item: Node3D) -> Node3D:
	if not is_instance_valid(item) or not stored_items.has(item):
		print("Item not in storage")
		return null
	
	# Find which slot has this item
	var target_slot = null
	for slot in storage_slots:
		if slot.occupied and slot.stored_item == item:
			target_slot = slot
			break
	
	if not target_slot:
		print("Item not found in any storage slot")
		return null
	
	# Mark slot as unoccupied
	target_slot.occupied = false
	target_slot.stored_item = null
	
	# Remove from stored items list
	stored_items.erase(item)
	
	# Remove from parent (self)
	remove_child(item)
	
	# Emit signal
	item_removed.emit(item)
	
	print("Item removed from storage: ", item.name)
	return item

# Called when player is holding this container and uses it on a pickable object
func collect_item(target_item: Node3D, player: Node) -> bool:
	if not is_instance_valid(target_item) or not (target_item is PickableObject):
		print("Target is not a valid pickable item")
		return false
	
	print("Attempting to collect: ", target_item.name)
	
	# Try to store the item
	var success = store_item(target_item)
	
	return success

# Signal handlers for the storage area
func _on_storage_area_body_entered(body: Node) -> void:
	if body is PickableObject and not stored_items.has(body):
		print("Pickable item entered storage area: ", body.name)

func _on_storage_area_body_exited(body: Node) -> void:
	if body is PickableObject:
		print("Pickable item exited storage area: ", body.name)

# Override from PickableObject to ensure items come with the container
func pickup(player: Node) -> void:
	# Make sure stored items stay with the container
	for item in stored_items:
		if item.get_parent() != self:
			var global_transform = item.global_transform
			if item.get_parent():
				item.get_parent().remove_child(item)
			add_child(item)
			item.global_transform = global_transform
			
			# Freeze physics
			if item is RigidBody3D and item.has_method("freeze_physics"):
				item.freeze_physics()
	
	# Call parent method to complete pickup
	super.pickup(player)
