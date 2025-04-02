## Base script for visible storage objects
## This can be attached to either static or pickable storage containers
extends Node3D

const VisibleStorageUtils = preload("res://scripts/VisibleStorageUtils.gd")
const PickableUtils = preload("res://scripts/PickableUtils.gd")

@export_group("Storage Properties")
@export var arrangement_type: VisibleStorageUtils.StorageArrangement = VisibleStorageUtils.StorageArrangement.GRID
@export var item_size: Vector3 = Vector3(0.1, 0.1, 0.1)  # Default size for items
@export var padding: float = 0.05  # Space between items
@export var max_weight: float = 10.0  # Maximum weight capacity
@export_group("Interaction")
@export var interact_text: String = "Press F to interact"
@export var is_pickable: bool = false  # Can this storage be picked up?

# Internal properties
var storage_slots: Array[VisibleStorageUtils.StorageSlot] = []
var current_weight: float = 0.0
var stored_items: Array[Node3D] = []

# Add getter for visualizer access
func get_storage_slots() -> Array:
	return storage_slots

# Reference to storage area - should be a child node with a CollisionShape
@onready var storage_area: Area3D = $StorageArea

func _ready() -> void:
	# Check for storage area
	if not storage_area:
		push_error("VisibleStorageObject requires a child node named 'StorageArea' with a CollisionShape3D")
		return
	
	# Calculate storage slots based on the actual storage area dimensions
	storage_slots = VisibleStorageUtils.calculate_storage_slots_from_area(
		storage_area,
		arrangement_type,
		item_size,
		padding
	)
	
	print("Created %d storage slots" % storage_slots.size())
	
	# Set up storage area signals
	storage_area.connect("body_entered", _on_storage_area_body_entered)
	storage_area.connect("body_exited", _on_storage_area_body_exited)

# Handle player interaction with the storage container
func interact(player: Node) -> void:
	print("Storage container interaction")
	# Could open UI, show stats, etc.
	
	# If the player is holding an item, try to store it
	if player.held_object:
		var item = player.held_object
		player.held_object = null  # Clear from player's hand
		
		# Try to add item to storage
		var success = store_item(item)
		if not success:
			# If storage failed, give back to player
			player.hold_item(item)

# Try to store an item
func store_item(item: Node3D) -> bool:
	# Check if there's space available
	var storage_usage = VisibleStorageUtils.calculate_storage_usage(storage_slots)
	
	if storage_usage.used_slots >= storage_usage.total_slots:
		print("Storage is full")
		return false
	
	# Check item weight if it has that property
	if item.get("weight") != null:
		if current_weight + item.weight > max_weight:
			print("Weight limit exceeded")
			return false
		current_weight += item.weight
	
	# Try to add the item to storage
	var success = VisibleStorageUtils.add_item_to_storage(self, item, storage_slots)
	
	if success:
		stored_items.append(item)
		
		# If the item has physics, freeze it
		if item is RigidBody3D:
			PickableUtils.freeze_physics(item)
	
	return success

# Remove an item from storage
func remove_item(item: Node3D) -> Node3D:
	# Find and remove the item
	var removed_item = VisibleStorageUtils.remove_item_from_storage(item, storage_slots)
	
	if removed_item:
		stored_items.erase(item)
		
		# Update weight if applicable
		if item.get("weight") != null:
			current_weight -= item.weight
		
		print("Removed item from storage: " + item.name)
	else:
		print("Failed to remove item from storage")
	
	return removed_item

# Handle pickup if this is a pickable storage container
func pickup(player: Node) -> void:
	if is_pickable:
		# First, make sure any stored items are properly parented to this container
		# so they move with it when picked up
		for item in stored_items:
			# Make sure the item stays child of this container
			if item.get_parent() != self:
				var global_transform = item.global_transform
				if item.get_parent():
					item.get_parent().remove_child(item)
				add_child(item)
				item.global_transform = global_transform
		
		# Now have the player pick up this container
		PickableUtils.pickup(self, player)

# Signal handling for storage area
func _on_storage_area_body_entered(body: Node) -> void:
	# Check if the body is a valid item that can be stored
	if body.has_method("pickup") and not stored_items.has(body):
		print("Valid item entered storage area: ", body.name)
		
		# Optionally, highlight or show UI prompt

func _on_storage_area_body_exited(body: Node) -> void:
	if body.has_method("pickup"):
		print("Item left storage area: ", body.name)
		
		# Remove any highlights or UI
