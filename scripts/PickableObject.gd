#pickable objects

extends RigidBody3D

@export var interact_text: String = "Press F to pick up"

const PickableUtils = preload("res://scripts/PickableUtils.gd")

func pickup(player: Node) -> void:
	PickableUtils.pickup(self, player)
