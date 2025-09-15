class_name WorldGenerator
extends Node

var noise: FastNoiseLite
var cave_noise: FastNoiseLite
var crystal_noise: FastNoiseLite
var seed_value: int = 0

func _init(world_seed: int = 0):
	seed_value = world_seed if world_seed != 0 else randi()
	setup_noise()

func setup_noise():
	# Terrain noise
	noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	
	# Cave noise
	cave_noise = FastNoiseLite.new()
	cave_noise.seed = seed_value + 1
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	cave_noise.frequency = 0.05
	cave_noise.fractal_octaves = 2
	
	# Crystal distribution noise
	crystal_noise = FastNoiseLite.new()
	crystal_noise.seed = seed_value + 2
	crystal_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	crystal_noise.frequency = 0.1

func generate_chunk(chunk: Chunk):
	var chunk_world_pos = chunk.chunk_position * Chunk.CHUNK_SIZE
	
	# First pass: Generate terrain
	for x in Chunk.CHUNK_SIZE:
		for z in Chunk.CHUNK_SIZE:
			var world_x = chunk_world_pos.x + x
			var world_z = chunk_world_pos.z + z
			
			# Generate height using noise
			var height = get_terrain_height(world_x, world_z)
			
			for y in Chunk.CHUNK_HEIGHT:
				var world_y = y
				var block_type = get_block_type_at(world_y, height)
				chunk.set_block(Vector3i(x, y, z), block_type)
	
	# Second pass: Generate caves and crystals
	for x in Chunk.CHUNK_SIZE:
		for z in Chunk.CHUNK_SIZE:
			var world_x = chunk_world_pos.x + x
			var world_z = chunk_world_pos.z + z
			
			for y in range(5, 45):  # Cave generation depth
				var cave_value = cave_noise.get_noise_3d(world_x * 0.05, y * 0.05, world_z * 0.05)
				
				if cave_value > 0.3:  # Cave threshold
					chunk.set_block(Vector3i(x, y, z), Block.BlockType.AIR)
					
					# Try to place crystals on cave walls
					if cave_value > 0.35 and y > 0:
						var crystal_chance = crystal_noise.get_noise_3d(world_x * 0.1, y * 0.1, world_z * 0.1)
						if crystal_chance > 0.7:  # Crystal spawn threshold
							var crystal_type = _get_crystal_for_depth(y)
							# Check if there's a solid block below (floor crystal)
							if y > 0 and chunk.get_block(Vector3i(x, y-1, z)) != Block.BlockType.AIR:
								chunk.set_block(Vector3i(x, y, z), crystal_type)

func get_terrain_height(x: int, z: int) -> int:
	var noise_value = noise.get_noise_2d(x, z)
	# Map noise from [-1, 1] to [20, 40] for height
	return int((noise_value + 1.0) * 10.0 + 20)

func get_block_type_at(y: int, surface_height: int) -> Block.BlockType:
	if y > surface_height:
		return Block.BlockType.AIR
	elif y == surface_height:
		return Block.BlockType.GRASS
	elif y >= surface_height - 3:
		return Block.BlockType.DIRT
	else:
		return Block.BlockType.STONE

func _get_crystal_for_depth(y: int) -> Block.BlockType:
	# Different crystals spawn at different depths
	var rand = randf()
	
	if y < 10:  # Very shallow
		if rand < 0.6:
			return Block.BlockType.CRYSTAL_AIR
		elif rand < 0.9:
			return Block.BlockType.CRYSTAL_ENERGY
		else:
			return Block.BlockType.CRYSTAL_EARTH
	elif y < 20:  # Shallow
		if rand < 0.4:
			return Block.BlockType.CRYSTAL_ENERGY
		elif rand < 0.7:
			return Block.BlockType.CRYSTAL_EARTH
		else:
			return Block.BlockType.CRYSTAL_WATER
	elif y < 30:  # Medium depth
		if rand < 0.3:
			return Block.BlockType.CRYSTAL_WATER
		elif rand < 0.6:
			return Block.BlockType.CRYSTAL_FIRE
		elif rand < 0.85:
			return Block.BlockType.CRYSTAL_EARTH
		else:
			return Block.BlockType.CRYSTAL_LUNAR
	elif y < 40:  # Deep
		if rand < 0.4:
			return Block.BlockType.CRYSTAL_FIRE
		elif rand < 0.7:
			return Block.BlockType.CRYSTAL_LUNAR
		elif rand < 0.95:
			return Block.BlockType.CRYSTAL_ENERGY
		else:
			return Block.BlockType.CRYSTAL_VOID
	else:  # Very deep
		if rand < 0.3:
			return Block.BlockType.CRYSTAL_LUNAR
		elif rand < 0.6:
			return Block.BlockType.CRYSTAL_FIRE
		elif rand < 0.9:
			return Block.BlockType.CRYSTAL_VOID
		else:
			return Block.BlockType.CRYSTAL_SOLAR  # Rare even at depth
	
	return Block.BlockType.CRYSTAL_ENERGY  # Default