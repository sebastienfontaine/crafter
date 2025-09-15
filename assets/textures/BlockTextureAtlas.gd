class_name BlockTextureAtlas
extends Resource

# Texture atlas configuration
const ATLAS_SIZE = 64   # 64x64 texture atlas 
const BLOCK_SIZE = 16   # Each block texture is 16x16 pixels
const BLOCKS_PER_ROW = 4  # 4 blocks per row

# UV coordinates for each block type (normalized 0-1)
var block_uvs: Dictionary = {}

func _init():
	setup_block_uvs()

func setup_block_uvs():
	# Calculate UV coordinates for each block type
	# Atlas layout (16x16 grid):
	# Row 0: Grass top, Grass side, Dirt, Stone
	# Row 1: Sand, Wood top, Wood side, Leaves
	
	var block_positions = {
		Block.BlockType.GRASS: {"top": Vector2(0, 0), "side": Vector2(1, 0), "bottom": Vector2(2, 0)},
		Block.BlockType.DIRT: {"all": Vector2(2, 0)},
		Block.BlockType.STONE: {"all": Vector2(3, 0)},
		Block.BlockType.SAND: {"all": Vector2(0, 1)},
		Block.BlockType.WOOD: {"top": Vector2(1, 1), "side": Vector2(2, 1)},
		Block.BlockType.LEAVES: {"all": Vector2(3, 1)}
	}
	
	# Convert positions to UV coordinates 
	var uv_size = 1.0 / BLOCKS_PER_ROW
	
	for block_type in block_positions:
		block_uvs[block_type] = {}
		var positions = block_positions[block_type]
		
		for face_type in positions:
			var pos = positions[face_type]
			var uv_min = Vector2(pos.x * uv_size, pos.y * uv_size)
			var uv_max = Vector2((pos.x + 1) * uv_size, (pos.y + 1) * uv_size)
			
			block_uvs[block_type][face_type] = {
				"min": uv_min,
				"max": uv_max,
				"corners": [
					Vector2(uv_min.x, uv_max.y),  # Bottom-left
					Vector2(uv_max.x, uv_max.y),  # Bottom-right
					Vector2(uv_max.x, uv_min.y),  # Top-right
					Vector2(uv_min.x, uv_min.y)   # Top-left
				]
			}
			

func get_block_uv_corners(block_type: Block.BlockType, face: String) -> Array:
	if block_type in block_uvs:
		var block_data = block_uvs[block_type]
		
		# Special handling for grass (different textures for different faces)
		if block_type == Block.BlockType.GRASS:
			match face:
				"top":
					return block_data.get("top", block_data.get("all", [])).get("corners", [])
				"bottom":
					return block_data.get("bottom", block_data.get("all", [])).get("corners", [])
				_:
					return block_data.get("side", block_data.get("all", [])).get("corners", [])
		
		# Special handling for wood
		elif block_type == Block.BlockType.WOOD:
			match face:
				"top", "bottom":
					return block_data.get("top", block_data.get("all", [])).get("corners", [])
				_:
					return block_data.get("side", block_data.get("all", [])).get("corners", [])
		
		# Default: use "all" texture for all faces
		else:
			return block_data.get("all", {}).get("corners", [])
	
	# Fallback UV coordinates (first texture in atlas)
	var uv_size = 1.0 / BLOCKS_PER_ROW
	return [
		Vector2(0, uv_size),
		Vector2(uv_size, uv_size),
		Vector2(uv_size, 0),
		Vector2(0, 0)
	]
