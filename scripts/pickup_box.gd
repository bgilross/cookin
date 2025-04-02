## Simple tray implementation of a visible storage object
extends RigidBody3D

const VisibleStorageUtils = preload("res://scripts/VisibleStorageUtils.gd")
const PickableUtils = preload("res://scripts/PickableUtils.gd")

@export var interact_text: String = "Press F to interact with tray"
@export var item_size: Vector3 = Vector3(0.1, 0.05, 0.1)  # Average size of items to store
@export var max_items: int = 100  # Maximum number of items (as a fallback)
@export var item_padding: float = 0.02  # Fixed the type from int to float

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
		item_padding
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
	print("Interacting with storage tray from: " + player.name)
	
	# If player is holding something, try to store it
	if "held_object" in player and player.held_object:
		var item = player.held_object
		
		# Try to store item before removing it from player
		if store_item(item):
			print("Item stored in tray: " + item.name)
			player.held_object = null
		else:
			print("Couldn't store item in tray")
	else:
		print("Player not holding anything to store")

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
	if not is_instance_valid(item):
		print("Invalid item reference")
		return false
		
	print("Attempting to store item: " + item.name)
	
	# Check if there's space
	if stored_items.size() >= storage_slots.size():
		print("Storage is full")
		return false
	
	# Try to add the item
	var success = VisibleStorageUtils.add_item_to_storage(self, item, storage_slots)
	
	if success:
		stored_items.append(item)
		
		# If it's a physics object, we need to freeze it
		if item is RigidBody3D:
			PickableUtils.freeze_physics(item)
		
		print("Successfully stored item: " + item.name)
	else:
		print("Failed to store item in slot")
	
	return success

# Remove an item from the tray
func remove_item(item: Node3D) -> Node3D:
	if not is_instance_valid(item):
		print("Invalid item reference")
		return null
		
	if not stored_items.has(item):
		print("Item not in storage")
		return null
	
	# Find which slot contains this item
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
	
	# Remove from stored items array
	stored_items.erase(item)
	
	# Prepare the item for independent existence
	if item.get_parent() == self:
		remove_child(item)
	
	# If it's a physics object, restore physics
	if item is RigidBody3D:
		PickableUtils.unfreeze_physics(item)
	
	print("Successfully removed item from tray: " + item.name)
	return item

# Signal handlers for the storage area
func _on_storage_area_body_entered(body: Node) -> void:
	if body.has_method("pickup") and not stored_items.has(body):
		print("Item entered tray area: ", body.name)
		# Could highlight or show UI prompt

func _on_storage_area_body_exited(body: Node) -> void:
	if body.has_method("pickup"):
		print("Item left tray area: ", body.name)
