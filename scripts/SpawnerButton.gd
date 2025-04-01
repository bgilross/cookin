#SpawnerButton.gd
extends StaticBody3D

@export var interact_text: String = "Press F to activate"
@export var scene_to_spawn: PackedScene 
@export var spawn_point: Node3D

func interact(player: Node) -> void:
	if not scene_to_spawn or not spawn_point:
		print("Missing scene or spawn point")
		return
		
	var spawned = scene_to_spawn.instantiate()
	spawned.global_transform = spawn_point.global_transform
	get_tree().current_scene.add_child(spawned)
	
	print("BUTTON is pressed: Spawned Object.")
