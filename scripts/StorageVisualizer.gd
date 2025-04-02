# StorageVisualizer.gd
extends MeshInstance3D

@export var debug_in_game: bool = false  # Show visualization during gameplay
@export var visualize_slots: bool = true # Enable/disable visualization
@export var slot_color_empty: Color = Color(0, 1, 0, 0.5)
@export var slot_color_filled: Color = Color(1, 0, 0, 0.5)

# Reference to parent storage object
var storage_parent
var debug_mesh: ImmediateMesh
var debug_material: StandardMaterial3D

func _ready():
	# Get reference to parent storage object
	storage_parent = get_parent()
	
	# Make sure parent has storage_slots
	if not storage_parent.has_method("get_storage_slots") and not "storage_slots" in storage_parent:
		push_error("StorageVisualizer parent must have storage_slots or get_storage_slots() method")
		return
	
	# Create immediate mesh for drawing
	debug_mesh = ImmediateMesh.new()
	mesh = debug_mesh
	
	# Create material
	debug_material = StandardMaterial3D.new()
	debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.vertex_color_use_as_albedo = true
	material_override = debug_material
	
	# Print debugging info
	print("StorageVisualizer initialized for: ", storage_parent.name)

func _process(_delta):
	# Only update visualization when needed
	if Engine.is_editor_hint() or debug_in_game:
		update_debug_visualization()

func update_debug_visualization():
	if not visualize_slots:
		debug_mesh = ImmediateMesh.new()
		mesh = debug_mesh
		return

	var slots = storage_parent.get_storage_slots() if storage_parent.has_method("get_storage_slots") else storage_parent.storage_slots
	if slots.size() == 0:
		return

	# Create a new mesh and begin drawing
	debug_mesh = ImmediateMesh.new()
	mesh = debug_mesh

	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for slot in slots:
		draw_slot_wireframe(slot)

	debug_mesh.surface_end()

func draw_slot_wireframe(slot):
	var slot_pos = slot.position
	
	var size := Vector3(0.1, 0.1, 0.1)
	if "size" in slot and typeof(slot.size) == TYPE_VECTOR3:
		size = slot.size
	size /= 2

	var color = slot_color_filled if ("occupied" in slot and slot.occupied) else slot_color_empty

	var corners = []
	for i in range(8):
		var x = slot_pos.x + (size.x if i & 1 else -size.x)
		var y = slot_pos.y + (size.y if i & 2 else -size.y)
		var z = slot_pos.z + (size.z if i & 4 else -size.z)
		corners.append(Vector3(x, y, z))

	var edges = [
		[0, 1], [1, 3], [3, 2], [2, 0],
		[4, 5], [5, 7], [7, 6], [6, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]
	]

	for edge in edges:
		debug_mesh.surface_set_color(color)
		debug_mesh.surface_add_vertex(corners[edge[0]])
		debug_mesh.surface_set_color(color)
		debug_mesh.surface_add_vertex(corners[edge[1]])
