class_name BlockRegistry
extends Node

static var blocks: Dictionary = {}

static func _static_init():
	register_blocks()

static func register_blocks():
	for block_type in Block.BlockType.values():
		var block = Block.new(block_type)
		blocks[block_type] = block

static func get_block(type: Block.BlockType) -> Block:
	return blocks.get(type, blocks[Block.BlockType.AIR])

static func is_solid(type: Block.BlockType) -> bool:
	var block = get_block(type)
	return block.is_solid if block else false

static func is_transparent(type: Block.BlockType) -> bool:
	var block = get_block(type)
	return block.is_transparent if block else true
