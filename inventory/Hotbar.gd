class_name Hotbar
extends Control

signal slot_selected(slot_index: int)
signal item_changed(slot_index: int, item: InventoryItem)
signal item_dropped_to_inventory(slot_index: int, item: InventoryItem)

const HOTBAR_SIZE = 10
const SLOT_SIZE = 40

var hotbar_slots: Array[InventoryItem] = []
var slot_buttons: Array[Button] = []
var selected_slot: int = 0

func _init():
	name = "Hotbar"
	# Position at bottom center manually
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	
	# Initialize empty slots
	hotbar_slots.resize(HOTBAR_SIZE)
	for i in range(HOTBAR_SIZE):
		hotbar_slots[i] = null

func _ready():
	create_hotbar_ui()

func create_hotbar_ui():
	# Background panel
	var panel = Panel.new()
	panel.size = Vector2(HOTBAR_SIZE * (SLOT_SIZE + 2) + 10, SLOT_SIZE + 10)
	panel.position = Vector2(-panel.size.x / 2, -panel.size.y - 10)
	add_child(panel)
	
	# Create hotbar slots
	slot_buttons.resize(HOTBAR_SIZE)
	for i in range(HOTBAR_SIZE):
		var button = Button.new()
		button.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		button.position = Vector2(5 + i * (SLOT_SIZE + 2), 5)
		
		# Style the button
		if i == selected_slot:
			button.modulate = Color(1.2, 1.2, 1.2)  # Highlight selected slot
		
		button.pressed.connect(_on_slot_clicked.bind(i))
		button.gui_input.connect(_on_slot_input.bind(i))
		panel.add_child(button)
		slot_buttons[i] = button
	
	# Add slot numbers
	for i in range(HOTBAR_SIZE):
		var label = Label.new()
		label.text = str((i + 1) % 10)  # 1-9, then 0
		label.add_theme_font_size_override("font_size", 10)
		label.position = Vector2(2, 2)
		slot_buttons[i].add_child(label)
	
	update_display()

func _on_slot_clicked(slot_index: int):
	select_slot(slot_index)

func _on_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right click to move item back to inventory
			var item = get_item(slot_index)
			if item != null and not item.is_empty():
				item_dropped_to_inventory.emit(slot_index, item)
				set_item(slot_index, null)

func select_slot(slot_index: int):
	if slot_index < 0 or slot_index >= HOTBAR_SIZE:
		return
	
	# Update visual selection
	if selected_slot < slot_buttons.size():
		slot_buttons[selected_slot].modulate = Color.WHITE
	
	selected_slot = slot_index
	
	if selected_slot < slot_buttons.size():
		slot_buttons[selected_slot].modulate = Color(1.2, 1.2, 1.2)
	
	slot_selected.emit(selected_slot)

func get_selected_item() -> InventoryItem:
	if selected_slot >= 0 and selected_slot < HOTBAR_SIZE:
		return hotbar_slots[selected_slot]
	return null

func set_item(slot_index: int, item: InventoryItem):
	if slot_index >= 0 and slot_index < HOTBAR_SIZE:
		hotbar_slots[slot_index] = item
		update_slot_display(slot_index)
		item_changed.emit(slot_index, item)

func get_item(slot_index: int) -> InventoryItem:
	if slot_index >= 0 and slot_index < HOTBAR_SIZE:
		return hotbar_slots[slot_index]
	return null

func try_add_item_from_inventory(item: InventoryItem) -> bool:
	# Try to find an empty slot or stack with existing item
	for i in range(HOTBAR_SIZE):
		var existing = hotbar_slots[i]
		if existing == null:
			# Empty slot, add here
			var new_item = InventoryItem.new(item.block_type, 1)
			set_item(i, new_item)
			return true
		elif existing.block_type == item.block_type and existing.quantity < existing.get_max_stack():
			# Can stack
			existing.quantity += 1
			update_slot_display(i)
			return true
	return false  # No space

func update_display():
	for i in range(HOTBAR_SIZE):
		update_slot_display(i)

func update_slot_display(slot_index: int):
	if slot_index >= slot_buttons.size():
		return
	
	var item = hotbar_slots[slot_index]
	var button = slot_buttons[slot_index]
	
	if item != null and not item.is_empty():
		var block = Block.new(item.block_type)
		var text = block.block_name
		if item.quantity > 1:
			text += "\n" + str(item.quantity)
		button.text = text
	else:
		button.text = ""

func _input(event):
	if event is InputEventKey and event.pressed:
		# Handle number keys 1-9, 0
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var slot = event.keycode - KEY_1
			select_slot(slot)
		elif event.keycode == KEY_0:
			select_slot(9)  # 0 key selects slot 10
	
	elif event is InputEventMouseButton:
		# Handle mouse scroll
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_slot = (selected_slot - 1) % HOTBAR_SIZE
			if new_slot < 0:
				new_slot = HOTBAR_SIZE - 1
			select_slot(new_slot)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_slot = (selected_slot + 1) % HOTBAR_SIZE
			select_slot(new_slot)