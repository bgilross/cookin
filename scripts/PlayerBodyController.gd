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
		if held_object:
			drop_held_object()
		elif current_target:
			if current_target.has_method("pickup"):
				current_target.pickup(self)
			elif current_target.has_method("interact"):
				current_target.interact(self)

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
	if held_object:
		var obj = held_object
		held_object = null
		
		# Use the utility function to handle dropping
		PickableUtils.drop_from_player(obj, self)

func hold_item(obj: Node3D) -> void:
	held_object = obj
	hold_position.add_child(obj)
