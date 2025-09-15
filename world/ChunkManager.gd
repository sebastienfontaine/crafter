class_name ChunkManager
extends Node

signal chunk_generated(chunk_data: Dictionary)

var generation_thread: Thread
var generation_mutex: Mutex
var chunk_queue: Array[Vector3i] = []
var generated_chunks: Array[Dictionary] = []
var world_generator: WorldGenerator
var texture_atlas: BlockTextureAtlas
var should_exit: bool = false

func _init():
	world_generator = WorldGenerator.new()
	texture_atlas = BlockTextureAtlas.new()
	generation_thread = Thread.new()
	generation_mutex = Mutex.new()

func start_generation_thread():
	if not generation_thread.is_started():
		generation_thread.start(_generation_thread_function)

func stop_generation_thread():
	generation_mutex.lock()
	should_exit = true
	generation_mutex.unlock()
	
	if generation_thread.is_started():
		generation_thread.wait_to_finish()

func _exit_tree():
	stop_generation_thread()

func request_chunk_generation(chunk_pos: Vector3i):
	generation_mutex.lock()
	if chunk_pos not in chunk_queue:
		chunk_queue.append(chunk_pos)
	generation_mutex.unlock()

func get_generated_chunks() -> Array[Dictionary]:
	generation_mutex.lock()
	var result = generated_chunks.duplicate()
	generated_chunks.clear()
	generation_mutex.unlock()
	return result

func _generation_thread_function():
	while true:
		generation_mutex.lock()
		var exit_requested = should_exit
		var has_work = chunk_queue.size() > 0
		var current_chunk_pos: Vector3i
		
		if has_work:
			current_chunk_pos = chunk_queue.pop_front()
		
		generation_mutex.unlock()
		
		if exit_requested:
			break
		
		if has_work:
			# Generate chunk data (without creating the actual Chunk node)
			var chunk_data = generate_chunk_data(current_chunk_pos)
			
			# Store the generated data
			generation_mutex.lock()
			generated_chunks.append(chunk_data)
			generation_mutex.unlock()
			
			# Signal that a chunk is ready (will be processed on main thread)
			call_deferred("emit_signal", "chunk_generated", chunk_data)
		else:
			# No work to do, sleep a bit
			OS.delay_msec(10)

func generate_chunk_data(chunk_pos: Vector3i) -> Dictionary:
	var blocks = []
	var chunk_world_pos = chunk_pos * Chunk.CHUNK_SIZE
	
	# Initialize blocks array
	for x in Chunk.CHUNK_SIZE:
		var plane = []
		for y in Chunk.CHUNK_HEIGHT:
			var column = []
			for z in Chunk.CHUNK_SIZE:
				column.append(Block.BlockType.AIR)
			plane.append(column)
		blocks.append(plane)
	
	# Generate terrain
	for x in Chunk.CHUNK_SIZE:
		for z in Chunk.CHUNK_SIZE:
			var world_x = chunk_world_pos.x + x
			var world_z = chunk_world_pos.z + z
			
			var height = world_generator.get_terrain_height(world_x, world_z)
			
			for y in Chunk.CHUNK_HEIGHT:
				var world_y = y
				var block_type = world_generator.get_block_type_at(world_y, height)
				blocks[x][y][z] = block_type
	
	# Pre-generate mesh data in thread
	var mesh_data = generate_mesh_data(blocks, chunk_pos)
	
	return {
		"position": chunk_pos,
		"blocks": blocks,
		"mesh_data": mesh_data
	}

func generate_mesh_data(blocks: Array, chunk_pos: Vector3i) -> Dictionary:
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()
	
	for x in Chunk.CHUNK_SIZE:
		for y in Chunk.CHUNK_HEIGHT:
			for z in Chunk.CHUNK_SIZE:
				var block_type = blocks[x][y][z]
				if block_type != Block.BlockType.AIR:
					add_block_to_mesh_data(Vector3i(x, y, z), block_type, blocks, vertices, normals, uvs, colors)
	
	return {
		"vertices": vertices,
		"normals": normals,
		"uvs": uvs,
		"colors": colors
	}

func add_block_to_mesh_data(pos: Vector3i, block_type: Block.BlockType, blocks: Array, vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray):
	var block_pos = Vector3(pos)
	
	# Check each face and add if visible
	if should_draw_face(pos + Vector3i(0, 1, 0), blocks):  # Top
		add_face_to_mesh_data(block_pos, 0, block_type, "top", vertices, normals, uvs, colors)
	if should_draw_face(pos + Vector3i(0, -1, 0), blocks):  # Bottom
		add_face_to_mesh_data(block_pos, 1, block_type, "bottom", vertices, normals, uvs, colors)
	if should_draw_face(pos + Vector3i(0, 0, 1), blocks):  # Front
		add_face_to_mesh_data(block_pos, 2, block_type, "side", vertices, normals, uvs, colors)
	if should_draw_face(pos + Vector3i(0, 0, -1), blocks):  # Back
		add_face_to_mesh_data(block_pos, 3, block_type, "side", vertices, normals, uvs, colors)
	if should_draw_face(pos + Vector3i(1, 0, 0), blocks):  # Right
		add_face_to_mesh_data(block_pos, 4, block_type, "side", vertices, normals, uvs, colors)
	if should_draw_face(pos + Vector3i(-1, 0, 0), blocks):  # Left
		add_face_to_mesh_data(block_pos, 5, block_type, "side", vertices, normals, uvs, colors)

func should_draw_face(neighbor_pos: Vector3i, blocks: Array) -> bool:
	if (neighbor_pos.x < 0 or neighbor_pos.x >= Chunk.CHUNK_SIZE or
		neighbor_pos.y < 0 or neighbor_pos.y >= Chunk.CHUNK_HEIGHT or
		neighbor_pos.z < 0 or neighbor_pos.z >= Chunk.CHUNK_SIZE):
		return true
	
	var neighbor_block = blocks[neighbor_pos.x][neighbor_pos.y][neighbor_pos.z]
	return BlockRegistry.is_transparent(neighbor_block)

func add_face_to_mesh_data(block_pos: Vector3, face: int, block_type: Block.BlockType, face_name: String, vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray):
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
	
	# Get UV coordinates from texture atlas
	var face_uvs = texture_atlas.get_block_uv_corners(block_type, face_name)
	if face_uvs.size() != 4:
		# Fallback if texture atlas fails
		face_uvs = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	
	# White color for texture atlas (no vertex coloring)
	var white = Color.WHITE
	
	# Add two triangles for the quad
	for i in [0, 1, 2]:
		vertices.append(face_vertices[i])
		normals.append(face_normal)
		uvs.append(face_uvs[i])
		colors.append(white)
	
	for i in [0, 2, 3]:
		vertices.append(face_vertices[i])
		normals.append(face_normal)
		uvs.append(face_uvs[i])
		colors.append(white)

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