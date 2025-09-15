class_name InventoryItem
extends Resource

var block_type: Block.BlockType
var quantity: int = 1

const MAX_STACK_SIZE = 64

func _init(type: Block.BlockType = Block.BlockType.AIR, qty: int = 1):
	block_type = type
	quantity = qty

func get_max_stack() -> int:
	return get_max_stack_for_block(block_type)

static func get_max_stack_for_block(block_type: Block.BlockType) -> int:
	# Different block types could have different stack sizes
	match block_type:
		Block.BlockType.AIR:
			return 0
		_:
			return MAX_STACK_SIZE

func get_block_name() -> String:
	var block = Block.new(block_type)
	return block.block_name

func is_empty() -> bool:
	return block_type == Block.BlockType.AIR or quantity <= 0