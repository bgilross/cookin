extends RigidBody3D

@export var interact_text: String = "Press F to pick up"

func interact(player: Node) -> void:
	if player.has_method("pick_up_object"):
		player.pick_up_object(self)
