extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

var pitch := 0.0 # Vertical Rotation
var current_target: Node = null
var held_object: Node3D = null

@onready var camera := $Camera3D
@onready var raycast := $Camera3D/RayCast3D
@onready var interact_label := $"../CanvasLayer/Label" #Path to LABEL
@onready var hold_position := $Camera3D/HoldPosition



func _ready() -> void:
		#Capture mouse movement:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		interact_label.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY) # YAW CONTROL
		pitch = clamp(pitch - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-89), deg_to_rad(89))
		camera.rotation.x = pitch # PITCH CONTROL

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	#INTERACTABLE CHECK
	
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var hit  = raycast.get_collider()
		if hit.has_method("interact"):
			current_target = hit
			if "interact_text" in hit:
				interact_label.text = hit.interact_text
			else:
				interact_label.text = "No Text Provided By Object!"
			interact_label.visible = true
		else:
			current_target = null
			interact_label.visible = false
	else:
		current_target = null
		interact_label.visible = false
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if held_object:
			drop_held_object()
		elif current_target:
			pick_up_object(current_target)


func pick_up_object(obj: Node3D) -> void:
	if obj is RigidBody3D:
		obj.freeze = true
		
		obj.linear_velocity = Vector3.ZERO
		obj.angular_velocity = Vector3.ZERO
		obj.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		
		
		obj.get_parent().remove_child(obj)
		hold_position.add_child(obj)
		obj.transform = Transform3D.IDENTITY # RESET poisition to CENTER of hold position
		var shape = obj.get_node_or_null("CollisionShape3D")
		if shape: 
			shape.disabled = true
		held_object = obj
		interact_label.visible = false # HIDE PROMPT
		
func drop_held_object() -> void:
	if held_object:
		var obj = held_object
		held_object = null
		
		hold_position.remove_child(obj)
		get_tree().root.add_child(obj) # DROP OBJ BACK into WORLD
		obj.global_transform = hold_position.global_transform
		
		var shape = obj.get_node_or_null("CollisionShape3D")
		if shape:
			shape.disabled = false
		
		obj.freeze = false
		obj.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		obj.sleeping = false
	
	
		
		
