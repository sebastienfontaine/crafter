class_name Block
extends Resource

enum BlockType {
	AIR,
	GRASS,
	DIRT,
	STONE,
	SAND,
	WOOD,
	LEAVES,
	# Crystal blocks
	CRYSTAL_ENERGY,
	CRYSTAL_FIRE,
	CRYSTAL_WATER,
	CRYSTAL_EARTH,
	CRYSTAL_AIR,
	CRYSTAL_VOID,
	CRYSTAL_SOLAR,
	CRYSTAL_LUNAR
}

@export var id: BlockType = BlockType.AIR
@export var block_name: String = "Air"
@export var is_solid: bool = false
@export var is_transparent: bool = true
@export var texture_top: Texture2D
@export var texture_bottom: Texture2D
@export var texture_sides: Texture2D

func _init(type: BlockType = BlockType.AIR):
	id = type
	setup_block_properties()

func setup_block_properties():
	match id:
		BlockType.AIR:
			block_name = "Air"
			is_solid = false
			is_transparent = true
		BlockType.GRASS:
			block_name = "Grass"
			is_solid = true
			is_transparent = false
		BlockType.DIRT:
			block_name = "Dirt"
			is_solid = true
			is_transparent = false
		BlockType.STONE:
			block_name = "Stone"
			is_solid = true
			is_transparent = false
		BlockType.SAND:
			block_name = "Sand"
			is_solid = true
			is_transparent = false
		BlockType.WOOD:
			block_name = "Wood"
			is_solid = true
			is_transparent = false
		BlockType.LEAVES:
			block_name = "Leaves"
			is_solid = true
			is_transparent = false
		# Crystal blocks
		BlockType.CRYSTAL_ENERGY:
			block_name = "Energy Crystal"
			is_solid = true
			is_transparent = true  # Crystals are semi-transparent
		BlockType.CRYSTAL_FIRE:
			block_name = "Fire Crystal"
			is_solid = true
			is_transparent = true
		BlockType.CRYSTAL_WATER:
			block_name = "Water Crystal"
			is_solid = true
			is_transparent = true
		BlockType.CRYSTAL_EARTH:
			block_name = "Earth Crystal"
			is_solid = true
			is_transparent = true
		BlockType.CRYSTAL_AIR:
			block_name = "Air Crystal"
			is_solid = true
			is_transparent = true
		BlockType.CRYSTAL_VOID:
			block_name = "Void Crystal"
			is_solid = true
			is_transparent = true
		BlockType.CRYSTAL_SOLAR:
			block_name = "Solar Crystal"
			is_solid = true
			is_transparent = true
		BlockType.CRYSTAL_LUNAR:
			block_name = "Lunar Crystal"
			is_solid = true
			is_transparent = true

func get_texture_for_face(face: int) -> Texture2D:
	if id == BlockType.GRASS:
		match face:
			0: return texture_top  # Top
			1: return texture_bottom  # Bottom
			_: return texture_sides  # Sides
	else:
		return texture_top if texture_top else null
