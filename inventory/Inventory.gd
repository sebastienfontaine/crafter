class_name Inventory
extends Resource

const INVENTORY_SIZE = 36  # 9x4 grid like Minecraft

var items: Array[InventoryItem] = []

func _init():
	# Initialize empty slots
	items.resize(INVENTORY_SIZE)
	for i in range(INVENTORY_SIZE):
		items[i] = null

func add_item(block_type: Block.BlockType, quantity: int = 1) -> bool:
	# Try to stack with existing items first
	for i in range(INVENTORY_SIZE):
		if items[i] != null and items[i].block_type == block_type:
			var added = min(quantity, items[i].get_max_stack() - items[i].quantity)
			items[i].quantity += added
			quantity -= added
			if quantity <= 0:
				return true
	
	# Find empty slots for remaining quantity
	while quantity > 0:
		var empty_slot = find_empty_slot()
		if empty_slot == -1:
			return false  # Inventory full
		
		var stack_size = min(quantity, InventoryItem.get_max_stack_for_block(block_type))
		items[empty_slot] = InventoryItem.new()
		items[empty_slot].block_type = block_type
		items[empty_slot].quantity = stack_size
		quantity -= stack_size
	
	return true

func remove_item(slot: int, quantity: int = 1) -> bool:
	if slot < 0 or slot >= INVENTORY_SIZE or items[slot] == null:
		return false
	
	if items[slot].quantity <= quantity:
		items[slot] = null
		return true
	else:
		items[slot].quantity -= quantity
		return true

func get_item(slot: int) -> InventoryItem:
	if slot < 0 or slot >= INVENTORY_SIZE:
		return null
	return items[slot]

func find_empty_slot() -> int:
	for i in range(INVENTORY_SIZE):
		if items[i] == null:
			return i
	return -1

func has_item(block_type: Block.BlockType, quantity: int = 1) -> bool:
	var total = 0
	for item in items:
		if item != null and item.block_type == block_type:
			total += item.quantity
			if total >= quantity:
				return true
	return false