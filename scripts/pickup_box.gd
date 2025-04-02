## Simple tray implementation of a visible storage object
extends RigidBody3D

const VisibleStorageUtils = preload("res://scripts/VisibleStorageUtils.gd")
const PickableUtils = preload("res://scripts/PickableUtils.gd")

@export var interact_text: String = "Press F to interact with tray"
@export var item_size: Vector3 = Vector3(0.1, 0.05, 0.1)  # Average size of items to store
@export var max_items: int = 6  # Maximum number of items (as a fallback)

# Storage properties
var storage_slots: Array[VisibleStorageUtils.StorageSlot] = []
var stored_items: Array[Node3D] = []

# Add getter for visualizer access
func get_storage_slots() -> Array:
	return storage_slots

@onready var storage_area: Area3D = $StorageArea

func _ready() -> void:
	# Check for storage area
	if not storage_area:
		push_error("pickup_box requires a child node named 'StorageArea' with a CollisionShape3D")
		return
		
	# Calculate storage slots based on the actual StorageArea dimensions
	storage_slots = VisibleStorageUtils.calculate_storage_slots_from_area(
		storage_area,
		VisibleStorageUtils.StorageArrangement.GRID,
		item_size,
		0.02  # Small padding between items
	)
	
	# Limit the number of slots to max_items if specified
	if max_items > 0 and storage_slots.size() > max_items:
		storage_slots = storage_slots.slice(0, max_items)
	
	print("Created %d storage slots for tray" % storage_slots.size())
	
	# Setup signals for the storage area
	storage_area.connect("body_entered", _on_storage_area_body_entered)
	storage_area.connect("body_exited", _on_storage_area_body_exited)

# Player interaction
func interact(player: Node) -> void:
	print("Interacting with storage tray")
	
	# If player is holding something, try to store it
	if player.held_object:
		var item = player.held_object
		player.held_object = null
		
		if store_item(item):
			print("Item stored in tray")
		else:
			# Give it back if storage failed
			player.hold_item(item)
			print("Couldn't store item in tray")

# Allow the tray to be picked up
func pickup(player: Node) -> void:
	print("Picking up tray with items")
	
	# Make sure all stored items are properly childed to the tray
	for item in stored_items:
		if item.get_parent() != self:
			var global_transform = item.global_transform
			if item.get_parent():
				item.get_parent().remove_child(item)
			add_child(item)
			item.global_transform = global_transform
			
			# Freeze physics on the item
			if item is RigidBody3D:
				PickableUtils.freeze_physics(item)
	
	# Use the pickable utilities to have the player pick up this tray
	PickableUtils.pickup(self, player)

# Store an item on the tray
func store_item(item: Node3D) -> bool:
	# Check if there's space
	if stored_items.size() >= storage_slots.size():
		return false
	
	# Try to add the item
	var success = VisibleStorageUtils.add_item_to_storage(self, item, storage_slots)
	
	if success:
		stored_items.append(item)
		
		# If it's a physics object, we need to freeze it
		if item is RigidBody3D:
			PickableUtils.freeze_physics(item)
	
	return success

# Remove an item from the tray
func remove_item(item: Node3D) -> Node3D:
	if not stored_items.has(item):
		return null
	
	var removed_item = VisibleStorageUtils.remove_item_from_storage(item, storage_slots)
	
	if removed_item:
		stored_items.erase(item)
	
	return removed_item

# Signal handlers for the storage area
func _on_storage_area_body_entered(body: Node) -> void:
	if body.has_method("pickup") and not stored_items.has(body):
		print("Item entered tray area: ", body.name)
		# Could highlight or show UI prompt

func _on_storage_area_body_exited(body: Node) -> void:
	if body.has_method("pickup"):
		print("Item left tray area: ", body.name)
