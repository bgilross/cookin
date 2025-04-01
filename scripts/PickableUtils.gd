## Utility script for handling common pickable item behavior
## Used by both RigidBody3D-based and Node3D-based pickables

extends Node

static func freeze_physics(obj: Node3D) -> void:
	if obj is RigidBody3D:
		obj.freeze = true
		obj.linear_velocity = Vector3.ZERO
		obj.angular_velocity = Vector3.ZERO
		obj.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

		var shape = obj.get_node_or_null("CollisionShape3D")
		if shape:
			shape.disabled = true

static func unfreeze_physics(obj: Node3D) -> void:
	if obj is RigidBody3D:
		obj.freeze = false
		obj.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		obj.sleeping = false

		var shape = obj.get_node_or_null("CollisionShape3D")
		if shape:
			shape.disabled = false

static func pickup(obj: Node3D, player: Node) -> void:
	if not player.has_method("hold_item"):
		return

	freeze_physics(obj)
	player.hold_item(obj)
	obj.transform = Transform3D.IDENTITY

static func drop(obj: Node3D, drop_transform: Transform3D) -> void:
	if not is_instance_valid(obj):
		print("[Drop] Error: Object is no longer valid.")
		return

	var tree = obj.get_tree()
	if not tree:
		print("[Drop] Error: get_tree() returned null.")
		return

	var scene_root = tree.current_scene
	if not scene_root:
		print("[Drop] Error: current_scene is null.")
		return

	obj.global_transform = drop_transform
	scene_root.add_child(obj)
	print("Dropped at:", drop_transform.origin)
	unfreeze_physics(obj)
