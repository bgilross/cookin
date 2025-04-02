# StorageVisualizer.gd - Visualizes storage slots for containers
extends MeshInstance3D
class_name StorageVisualizer

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
	
	# Create immediate mesh for drawing
	debug_mesh = ImmediateMesh.new()
	mesh = debug_mesh
	
	# Create material
	debug_material = StandardMaterial3D.new()
	debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	debug_material.vertex_color_use_as_albedo = true
	material_override = debug_material

func _process(_delta):
	# Only update visualization when needed
	if Engine.is_editor_hint() or debug_in_game:
		update_debug_visualization()

func update_debug_visualization():
	if not visualize_slots:
		debug_mesh.clear_surfaces()
		return

	# Get slots from parent
	var slots = []
	
	if storage_parent is StorageObject:
		slots = storage_parent.storage_slots
	elif "storage_slots" in storage_parent:
		slots = storage_parent.storage_slots
	else:
		return
	
	if slots.size() == 0:
		return

	# Clear existing mesh
	debug_mesh.clear_surfaces()
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for slot in slots:
		draw_slot_wireframe(slot)

	debug_mesh.surface_end()

func draw_slot_wireframe(slot):
	# Get slot properties
	var slot_pos = slot.position
	var size = slot.size / 2 if "size" in slot else Vector3(0.05, 0.05, 0.05)
	var color = slot_color_filled if slot.occupied else slot_color_empty

	# Calculate the 8 corners of the cube
	var corners = []
	for i in range(8):
		var x = slot_pos.x + (size.x if i & 1 else -size.x)
		var y = slot_pos.y + (size.y if i & 2 else -size.y)
		var z = slot_pos.z + (size.z if i & 4 else -size.z)
		corners.append(Vector3(x, y, z))

	# Define edges of the cube
	var edges = [
		[0, 1], [1, 3], [3, 2], [2, 0],  # Bottom face
		[4, 5], [5, 7], [7, 6], [6, 4],  # Top face
		[0, 4], [1, 5], [2, 6], [3, 7]   # Connecting edges
	]

	# Draw the edges
	for edge in edges:
		debug_mesh.surface_set_color(color)
		debug_mesh.surface_add_vertex(corners[edge[0]])
		debug_mesh.surface_set_color(color)
		debug_mesh.surface_add_vertex(corners[edge[1]])
