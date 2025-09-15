class_name WorldGenerator
extends Node

var noise: FastNoiseLite
var seed_value: int = 0

func _init(world_seed: int = 0):
	seed_value = world_seed if world_seed != 0 else randi()
	setup_noise()

func setup_noise():
	noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.02
	noise.fractal_octaves = 4

func generate_chunk(chunk: Chunk):
	var chunk_world_pos = chunk.chunk_position * Chunk.CHUNK_SIZE
	
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