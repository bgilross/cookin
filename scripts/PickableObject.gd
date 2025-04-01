extends RigidBody3D

@export var interact_text: String = "Press F to pick up"

const PickableUtils = preload("res://scripts/PickableUtils.gd")

func pickup(player: Node) -> void:
	if not player.has_method("hold_item"):
		return

	# Do physics logic inside this object
	PickableUtils.freeze_physics(self)

	# Reparent to player hold slot
	var old_parent = get_parent()
	old_parent.remove_child(self)
	player.hold_item(self)  # Let player attach and track
	self.transform = Transform3D.IDENTITY
