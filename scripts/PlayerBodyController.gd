extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002
const GRAVITY_VALUE = -9.8

var pitch := 0.0
var current_target: Node = null
var held_object: Node3D = null
var push_force := 1.1

const PickableUtils = preload("res://scripts/PickableUtils.gd")

@onready var camera := $Camera3D
@onready var raycast := $Camera3D/RayCast3D
@onready var interact_label := $"../CanvasLayer/Label"
@onready var hold_position := $Camera3D/HoldPosition
@onready var push_area := $PushArea

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interact_label.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch = clamp(pitch - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	move_and_slide()
	handle_interaction_raycast()
	handle_push_collisions()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		# Handle interaction with current target or held object
		if current_target:
			print("Interacting with: " + current_target.name)
			if held_object and current_target.has_method("interact"):
				current_target.interact(self)
			elif not held_object and current_target.has_method("pickup"):
				current_target.pickup(self)
			elif not held_object and current_target.has_method("interact"):
				current_target.interact(self)
	
	# Use G key (drop action) exclusively for dropping
	if event.is_action_pressed("drop") and held_object:
		handle_drop_action()

func handle_push_collisions():
	for body in push_area.get_overlapping_bodies():
		if body is RigidBody3D:
			var dir = (body.global_position - global_position).normalized()
			dir.y = 0
			body.apply_impulse(dir * push_force)

# ----------------------------
# Movement
# ----------------------------
func handle_movement(delta: float) -> void:
	if not is_on_floor():
		# Apply gravity directly instead of using get_gravity()
		velocity.y += GRAVITY_VALUE * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
# ----------------------------
# Interaction
# ----------------------------
func handle_interaction_raycast() -> void:
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit.has_method("pickup") or hit.has_method("interact"):
			current_target = hit
			if "interact_text" in hit:
				interact_label.text = hit.interact_text
			else:
				interact_label.text = "Press F"
			interact_label.visible = true
			return
	
	current_target = null
	interact_label.visible = false

# ----------------------------
# Holding
# ----------------------------
func drop_held_object() -> void:
	if not held_object:
		return
		
	print("Dropping held object: " + held_object.name)
	var obj = held_object
	held_object = null  # Clear reference BEFORE dropping to avoid recursive issues
	
	# Use the utility function to handle dropping
	PickableUtils.drop_from_player(obj, self)
	
	print("Drop complete")

func hold_item(obj: Node3D) -> void:
	if not is_instance_valid(obj):
		print("Attempted to hold invalid object")
		return
		
	# Clear any existing held object first
	if held_object:
		drop_held_object()
	
	print("Player picked up: " + obj.name)
	held_object = obj
	
	# Make sure object isn't already in the scene tree somewhere else
	if obj.get_parent():
		obj.get_parent().remove_child(obj)
		
	hold_position.add_child(obj)
	
	# Reset object transform relative to hold position
	obj.transform = Transform3D.IDENTITY

# ----------------------------
# New Drop Functionality
# ----------------------------
func handle_drop_action() -> void:
	if not held_object:
		return
		
	# Check if held object is a storage container
	var is_storage_container = false
	var has_stored_items = false
	
	# First check if it's a VisibleStorageObject or has methods/properties related to storage
	if held_object.has_method("get_storage_slots") or "storage_slots" in held_object:
		is_storage_container = true
		
		# Get stored items if available
		if "stored_items" in held_object and held_object.stored_items.size() > 0:
			has_stored_items = true
			print("Storage container has " + str(held_object.stored_items.size()) + " items")
	
	# If it's not a storage container or has no items, just drop it
	if not is_storage_container or not has_stored_items:
		print("Dropping held object (not a storage container or empty)")
		drop_held_object()
		return
	
	# Drop one item from the storage container
	var items = held_object.stored_items
	if items.size() > 0:
		# Get the last item in the container
		var item_to_drop = items[items.size() - 1]
		print("Attempting to drop item from container: " + item_to_drop.name)
		
		# Make sure the item is a valid node
		if not is_instance_valid(item_to_drop):
			print("Invalid item reference")
			return
		
		# Remove it from the container first
		var removed_item = null
		if held_object.has_method("remove_item"):
			removed_item = held_object.remove_item(item_to_drop)
		
		# If removal was successful
		if removed_item:
			# Calculate drop position - slightly in front of player
			var drop_transform = PickableUtils.calculate_drop_position(self)
			
			# Drop the item
			PickableUtils.drop(removed_item, drop_transform)
			print("Successfully dropped item from container")
		else:
			print("Failed to remove item from container")
