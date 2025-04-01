extends RigidBody3D

@export var interact_text: String = "Press E to pick up!"

func interact(): 
	print("Picked up: %s" % name)
	# destroy for now?
	queue_free()

#optional future hooks?

func can_interact() -> bool:
	return true
	
	
