# Interactable.gd - Base class for all interactable objects
extends Node3D
class_name Interactable

## Base text shown when hovering over this object
@export var interact_text: String = "Press F to interact"
@export var use_text: String = "Press E to use"

## Override these methods in derived classes to implement behavior

## Called when player presses F while looking at this object
func interact(player: Node) -> void:
	print("Base interact method called on: ", name)
	
## Called when player presses E while looking at this object
func use(player: Node) -> void:
	print("Base use method called on: ", name)
	
## Called when player holds another object and presses E while looking at this object
func receive_use(player: Node, used_object: Node3D) -> void:
	print("Object ", used_object.name, " used on ", name)
	
## Optional: Can this object be interacted with?
func can_interact() -> bool:
	return true
	
## Optional: Can this object be used?
func can_use() -> bool:
	return true
	
## Optional: Can this object receive use from another object?
func can_receive_use(used_object: Node3D) -> bool:
	return true
