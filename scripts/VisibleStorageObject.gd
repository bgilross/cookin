
extends Node3D

@onready var storage_area: Area3D = find_child("StorageArea", true, false)
@export var spacing: Vector3 = Vector3(0.05, 0.05, 0.05)  # Gap between stacked items

var stored_items: Array[Node3D] = []

func _ready():
	if not storage_area:
		push_warning("VisibleStorageItem: No child named 'StorageArea' found.")

func try_store(item: Node3D) -> bool:
	if not storage_area:
		return false

	var volume_aabb = storage_area.get_aabb()
	var item_aabb = item.get_aabb()
	var item_size = item_aabb.size + spacing
	var index = stored_items.size()

	var max_columns = int(volume_aabb.size.x / item_size.x)
	var max_rows = int(volume_aabb.size.z / item_size.z)
	var max_layers = int(volume_aabb.size.y / item_size.y)

	var layer = index / (max_columns * max_rows)
	var row = (index / max_columns) % max_rows
	var column = index % max_columns

	if layer >= max_layers:
		print("[Storage] No space left for more items.")
		return false

	var pos_local = Vector3(
		column * item_size.x,
		layer * item_size.y,
		row * item_size.z
	)

	var pos_global = storage_area.global_transform.origin + pos_local

	item.get_parent().remove_child(item)
	add_child(item)
	item.global_transform.origin = pos_global
	stored_items.append(item)
	return true
