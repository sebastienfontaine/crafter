class_name Chunk
extends Node3D

const CHUNK_SIZE = 16
const CHUNK_HEIGHT = 64

var chunk_position: Vector3i
var blocks: Array = []
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var static_body: StaticBody3D
var is_dirty: bool = true
var material: StandardMaterial3D
var shared_material: StandardMaterial3D  # Passed from World

func _init(pos: Vector3i = Vector3i.ZERO):
	chunk_position = pos
	initialize_blocks()

func initialize_blocks():
	blocks = []
	for x in CHUNK_SIZE:
		var plane = []
		for y in CHUNK_HEIGHT:
			var column = []
			for z in CHUNK_SIZE:
				column.append(Block.BlockType.AIR)
			plane.append(column)
		blocks.append(plane)

func _ready():
	static_body = StaticBody3D.new()
	add_child(static_body)
	
	collision_shape = CollisionShape3D.new()
	static_body.add_child(collision_shape)
	
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Use shared material if available, otherwise create own
	if shared_material:
		material = shared_material
	else:
		# Fallback: create own material
		material = StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 1.0
		material.metallic = 0.0
	
	position = Vector3(chunk_position.x * CHUNK_SIZE, 0, chunk_position.z * CHUNK_SIZE)

func set_block(local_pos: Vector3i, block_type: Block.BlockType):
	if is_position_valid(local_pos):
		blocks[local_pos.x][local_pos.y][local_pos.z] = block_type
		is_dirty = true

func get_block(local_pos: Vector3i) -> Block.BlockType:
	if is_position_valid(local_pos):
		return blocks[local_pos.x][local_pos.y][local_pos.z]
	return Block.BlockType.AIR

func is_position_valid(pos: Vector3i) -> bool:
	return pos.x >= 0 and pos.x < CHUNK_SIZE and \
		   pos.y >= 0 and pos.y < CHUNK_HEIGHT and \
		   pos.z >= 0 and pos.z < CHUNK_SIZE

func update_mesh():
	if not is_dirty:
		return
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()
	
	var block_count = 0
	# Generate mesh data
	for x in CHUNK_SIZE:
		for y in CHUNK_HEIGHT:
			for z in CHUNK_SIZE:
				var block_type = blocks[x][y][z]
				if block_type != Block.BlockType.AIR:
					block_count += 1
					add_block_to_mesh(Vector3i(x, y, z), block_type, vertices, normals, uvs, colors)
	
	
	if vertices.size() == 0:
		if mesh_instance.mesh:
			mesh_instance.mesh = null
		if collision_shape.shape:
			collision_shape.shape = null
		is_dirty = false
		return
	
	# Create mesh
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_material(0, material)
	
	mesh_instance.mesh = array_mesh
	
	# Create collision shape
	if array_mesh:
		collision_shape.shape = array_mesh.create_trimesh_shape()
	
	is_dirty = false

func apply_mesh_data(mesh_data: Dictionary):
	var vertices = mesh_data.vertices
	var normals = mesh_data.normals
	var uvs = mesh_data.uvs
	var colors = mesh_data.colors
	
	if vertices.size() == 0:
		if mesh_instance.mesh:
			mesh_instance.mesh = null
		if collision_shape.shape:
			collision_shape.shape = null
		return
	
	# Create mesh from pre-generated data
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_material(0, material)
	
	mesh_instance.mesh = array_mesh
	
	# Create collision shape
	if array_mesh:
		collision_shape.shape = array_mesh.create_trimesh_shape()
	

func add_block_to_mesh(pos: Vector3i, block_type: Block.BlockType, vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray):
	var color = get_block_color(block_type)
	var block_pos = Vector3(pos)
	
	# Check each face and add if visible
	# Top face (Y+)
	if should_draw_face(pos + Vector3i(0, 1, 0)):
		add_face_to_mesh(block_pos, 0, block_type, "top", color, vertices, normals, uvs, colors)
	
	# Bottom face (Y-)
	if should_draw_face(pos + Vector3i(0, -1, 0)):
		add_face_to_mesh(block_pos, 1, block_type, "bottom", color, vertices, normals, uvs, colors)
	
	# Front face (Z+)
	if should_draw_face(pos + Vector3i(0, 0, 1)):
		add_face_to_mesh(block_pos, 2, block_type, "side", color, vertices, normals, uvs, colors)
	
	# Back face (Z-)
	if should_draw_face(pos + Vector3i(0, 0, -1)):
		add_face_to_mesh(block_pos, 3, block_type, "side", color, vertices, normals, uvs, colors)
	
	# Right face (X+)
	if should_draw_face(pos + Vector3i(1, 0, 0)):
		add_face_to_mesh(block_pos, 4, block_type, "side", color, vertices, normals, uvs, colors)
	
	# Left face (X-)
	if should_draw_face(pos + Vector3i(-1, 0, 0)):
		add_face_to_mesh(block_pos, 5, block_type, "side", color, vertices, normals, uvs, colors)

func add_face_to_mesh(block_pos: Vector3, face: int, block_type: Block.BlockType, face_name: String, color: Color, vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray):
	var face_vertices = []
	var face_normal = Vector3.ZERO
	
	match face:
		0:  # Top
			face_vertices = [
				block_pos + Vector3(0, 1, 0),
				block_pos + Vector3(1, 1, 0),
				block_pos + Vector3(1, 1, 1),
				block_pos + Vector3(0, 1, 1)
			]
			face_normal = Vector3.UP
		1:  # Bottom
			face_vertices = [
				block_pos + Vector3(0, 0, 1),
				block_pos + Vector3(1, 0, 1),
				block_pos + Vector3(1, 0, 0),
				block_pos + Vector3(0, 0, 0)
			]
			face_normal = Vector3.DOWN
		2:  # Front
			face_vertices = [
				block_pos + Vector3(0, 0, 1),
				block_pos + Vector3(0, 1, 1),
				block_pos + Vector3(1, 1, 1),
				block_pos + Vector3(1, 0, 1)
			]
			face_normal = Vector3.FORWARD
		3:  # Back
			face_vertices = [
				block_pos + Vector3(1, 0, 0),
				block_pos + Vector3(1, 1, 0),
				block_pos + Vector3(0, 1, 0),
				block_pos + Vector3(0, 0, 0)
			]
			face_normal = Vector3.BACK
		4:  # Right
			face_vertices = [
				block_pos + Vector3(1, 0, 0),
				block_pos + Vector3(1, 0, 1),
				block_pos + Vector3(1, 1, 1),
				block_pos + Vector3(1, 1, 0)
			]
			face_normal = Vector3.RIGHT
		5:  # Left
			face_vertices = [
				block_pos + Vector3(0, 0, 1),
				block_pos + Vector3(0, 0, 0),
				block_pos + Vector3(0, 1, 0),
				block_pos + Vector3(0, 1, 1)
			]
			face_normal = Vector3.LEFT
	
	# Get correct UV coordinates from texture atlas (static instance)
	var atlas = BlockTextureAtlas.new()
	var face_uvs = atlas.get_block_uv_corners(block_type, face_name)
	
	# Fallback if no UV found
	if face_uvs.size() != 4:
		face_uvs = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	
	# Add two triangles for the quad
	# First triangle: 0, 1, 2
	for i in [0, 1, 2]:
		vertices.append(face_vertices[i])
		normals.append(face_normal)
		uvs.append(face_uvs[i])
		colors.append(color)
	
	# Second triangle: 0, 2, 3
	for i in [0, 2, 3]:
		vertices.append(face_vertices[i])
		normals.append(face_normal)
		uvs.append(face_uvs[i])
		colors.append(color)

func should_draw_face(neighbor_pos: Vector3i) -> bool:
	if not is_position_valid(neighbor_pos):
		return true
	
	var neighbor_block = get_block(neighbor_pos)
	return BlockRegistry.is_transparent(neighbor_block)

func get_block_color(block_type: Block.BlockType) -> Color:
	match block_type:
		Block.BlockType.GRASS:
			return Color(0.2, 0.7, 0.2)
		Block.BlockType.DIRT:
			return Color(0.5, 0.35, 0.2)
		Block.BlockType.STONE:
			return Color(0.5, 0.5, 0.5)
		Block.BlockType.SAND:
			return Color(0.9, 0.85, 0.5)
		Block.BlockType.WOOD:
			return Color(0.6, 0.4, 0.2)
		Block.BlockType.LEAVES:
			return Color(0.1, 0.5, 0.1)
		_:
			return Color.WHITE
