class_name World
extends Node3D

var chunks: Dictionary = {}
var chunk_manager: ChunkManager
var render_distance: int = 2  # Reduced for better performance
var player: Node3D
var last_player_chunk: Vector3i = Vector3i(-999, -999, -999)
var pending_chunks: Dictionary = {}  # Track chunks being generated
var shared_material: StandardMaterial3D  # Shared material for all chunks

func _ready():
	# Create and configure chunk manager first
	chunk_manager = ChunkManager.new()
	add_child(chunk_manager)
	chunk_manager.chunk_generated.connect(_on_chunk_generated)
	
	# Create shared material for all chunks
	create_shared_material()
	
	# Start generation thread
	chunk_manager.start_generation_thread()
	
	generate_initial_world()

func create_shared_material():
	shared_material = StandardMaterial3D.new()
	
	# Try to load the texture atlas
	var atlas_texture = load("res://assets/textures/block_atlas.tres")
	if atlas_texture:
		shared_material.albedo_texture = atlas_texture
	else:
		# Fallback to vertex colors if no texture
		shared_material.vertex_color_use_as_albedo = true
	
	shared_material.roughness = 1.0
	shared_material.metallic = 0.0
	shared_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Pixel perfect filtering

func generate_initial_world():
	for x in range(-render_distance, render_distance + 1):
		for z in range(-render_distance, render_distance + 1):
			load_chunk(Vector3i(x, 0, z))

func load_chunk(chunk_pos: Vector3i):
	var key = chunk_key(chunk_pos)
	if key in chunks or key in pending_chunks:
		return
	
	# Mark chunk as pending and request generation
	pending_chunks[key] = true
	chunk_manager.request_chunk_generation(chunk_pos)

func _on_chunk_generated(chunk_data: Dictionary):
	var chunk_pos = chunk_data.position
	var key = chunk_key(chunk_pos)
	
	# Remove from pending
	pending_chunks.erase(key)
	
	# Create the actual chunk node on main thread
	var chunk = Chunk.new(chunk_pos)
	chunk.blocks = chunk_data.blocks
	chunk.shared_material = shared_material  # Pass shared material
	add_child(chunk)
	chunks[key] = chunk
	
	# Apply pre-generated mesh data (super fast!)
	chunk.apply_mesh_data(chunk_data.mesh_data)

func _exit_tree():
	if chunk_manager:
		chunk_manager.stop_generation_thread()

func unload_chunk(chunk_pos: Vector3i):
	var key = chunk_key(chunk_pos)
	if key in chunks:
		chunks[key].queue_free()
		chunks.erase(key)
	# Also remove from pending if it was being generated
	pending_chunks.erase(key)

func chunk_key(pos: Vector3i) -> String:
	return "%d_%d_%d" % [pos.x, pos.y, pos.z]

func world_to_chunk_position(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		floor(world_pos.x / Chunk.CHUNK_SIZE),
		0,
		floor(world_pos.z / Chunk.CHUNK_SIZE)
	)

func world_to_block_position(world_pos: Vector3) -> Vector3i:
	return Vector3i(floor(world_pos.x), floor(world_pos.y), floor(world_pos.z))

func get_block_at_world_position(world_pos: Vector3) -> Block.BlockType:
	var chunk_pos = world_to_chunk_position(world_pos)
	var key = chunk_key(chunk_pos)
	
	if not key in chunks:
		return Block.BlockType.AIR
	
	var chunk = chunks[key]
	
	# Calculate local position within chunk
	var local_pos = Vector3i(
		int(floor(world_pos.x)) - (chunk_pos.x * Chunk.CHUNK_SIZE),
		int(floor(world_pos.y)),
		int(floor(world_pos.z)) - (chunk_pos.z * Chunk.CHUNK_SIZE)
	)
	
	if not chunk.is_position_valid(local_pos):
		return Block.BlockType.AIR
	
	return chunk.get_block(local_pos)

func set_block_at_world_position(world_pos: Vector3, block_type: Block.BlockType):
	var chunk_pos = world_to_chunk_position(world_pos)
	var key = chunk_key(chunk_pos)
	
	if not key in chunks:
		print("Chunk not loaded at: ", chunk_pos)
		return
	
	var chunk = chunks[key]
	
	# Calculate local position within chunk
	var local_pos = Vector3i(
		int(floor(world_pos.x)) - (chunk_pos.x * Chunk.CHUNK_SIZE),
		int(floor(world_pos.y)),
		int(floor(world_pos.z)) - (chunk_pos.z * Chunk.CHUNK_SIZE)
	)
	
	# Verify the local position is valid
	if not chunk.is_position_valid(local_pos):
		print("Invalid local position: ", local_pos)
		return
	
	# Get the current block at this position
	var current_block = chunk.get_block(local_pos)
	print("Setting block at World: ", world_pos, " Local: ", local_pos, " from ", current_block, " to ", block_type)
	
	# Only update if actually changing the block
	if current_block == block_type:
		print("Block already is type: ", block_type)
		return
	
	chunk.set_block(local_pos, block_type)
	chunk.update_mesh()
	print("Mesh updated for chunk at ", chunk_pos)
	
	# Update neighboring chunks if on edge
	update_neighboring_chunks_if_needed(world_pos, chunk_pos)

func update_neighboring_chunks_if_needed(world_pos: Vector3, chunk_pos: Vector3i):
	var local_x = int(floor(world_pos.x)) - (chunk_pos.x * Chunk.CHUNK_SIZE)
	var local_z = int(floor(world_pos.z)) - (chunk_pos.z * Chunk.CHUNK_SIZE)
	
	if local_x == 0:
		update_chunk_at(chunk_pos + Vector3i(-1, 0, 0))
	elif local_x == Chunk.CHUNK_SIZE - 1:
		update_chunk_at(chunk_pos + Vector3i(1, 0, 0))
	
	if local_z == 0:
		update_chunk_at(chunk_pos + Vector3i(0, 0, -1))
	elif local_z == Chunk.CHUNK_SIZE - 1:
		update_chunk_at(chunk_pos + Vector3i(0, 0, 1))

func update_chunk_at(chunk_pos: Vector3i):
	var key = chunk_key(chunk_pos)
	if key in chunks:
		chunks[key].update_mesh()

func update_chunks_around_player():
	if not player:
		return
	
	var player_chunk = world_to_chunk_position(player.global_position)
	
	# Only update if player moved to a different chunk
	if player_chunk == last_player_chunk:
		return
	
	last_player_chunk = player_chunk
	
	# Load new chunks
	for x in range(-render_distance, render_distance + 1):
		for z in range(-render_distance, render_distance + 1):
			var chunk_pos = player_chunk + Vector3i(x, 0, z)
			load_chunk(chunk_pos)
	
	# Unload far chunks
	var chunks_to_unload = []
	for key in chunks:
		var chunk = chunks[key]
		var distance = Vector3(chunk.chunk_position).distance_to(Vector3(player_chunk))
		if distance > render_distance + 1:
			chunks_to_unload.append(chunk.chunk_position)
	
	for chunk_pos in chunks_to_unload:
		unload_chunk(chunk_pos)
