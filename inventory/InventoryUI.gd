class_name InventoryUI
extends Control

signal slot_clicked(slot_index: int)
signal item_dragged(from_slot: int, item: InventoryItem)
signal close_requested()

var inventory: Inventory
var slot_buttons: Array[Button] = []
var is_open: bool = false

const SLOT_SIZE = 40
const SLOTS_PER_ROW = 9
const INVENTORY_ROWS = 4

func _init():
	name = "InventoryUI"
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	visible = false

func _ready():
	create_inventory_grid()

func setup_inventory(inv: Inventory):
	inventory = inv
	if not slot_buttons.is_empty():
		update_display()

func create_inventory_grid():
	# Background panel
	var panel = Panel.new()
	panel.size = Vector2(SLOTS_PER_ROW * (SLOT_SIZE + 5) + 10, INVENTORY_ROWS * (SLOT_SIZE + 5) + 30)
	panel.position = Vector2(-panel.size.x / 2, -panel.size.y / 2)
	add_child(panel)
	
	# Title
	var title = Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 16)
	title.position = Vector2(10, 5)
	panel.add_child(title)
	
	# Create inventory slots
	slot_buttons.resize(Inventory.INVENTORY_SIZE)
	for i in range(Inventory.INVENTORY_SIZE):
		var button = Button.new()
		button.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		
		var row = i / SLOTS_PER_ROW
		var col = i % SLOTS_PER_ROW
		button.position = Vector2(5 + col * (SLOT_SIZE + 5), 25 + row * (SLOT_SIZE + 5))
		
		button.pressed.connect(_on_slot_clicked.bind(i))
		button.gui_input.connect(_on_slot_input.bind(i))
		panel.add_child(button)
		slot_buttons[i] = button

func _on_slot_clicked(slot_index: int):
	slot_clicked.emit(slot_index)

func _on_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Start potential drag
			var item = inventory.get_item(slot_index)
			if item != null and not item.is_empty():
				print("Starting drag from inventory slot ", slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Right click to move single item to hotbar
			var item = inventory.get_item(slot_index)
			if item != null and not item.is_empty():
				item_dragged.emit(slot_index, item)

func toggle():
	is_open = !is_open
	visible = is_open
	
	if is_open:
		# Only update display if buttons are ready
		if not slot_buttons.is_empty():
			update_display()
		# Capture mouse when inventory is open
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		# Return to captured mode when closed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	close_requested.emit()

func update_display():
	if not inventory or slot_buttons.is_empty():
		return
		
	for i in range(Inventory.INVENTORY_SIZE):
		if i >= slot_buttons.size():
			break
			
		var item = inventory.get_item(i)
		var button = slot_buttons[i]
		
		if button == null:
			continue
		
		if item != null and not item.is_empty():
			# Show block type and quantity
			var block = Block.new(item.block_type)
			var text = block.block_name
			if item.quantity > 1:
				text += "\n" + str(item.quantity)
			button.text = text
		else:
			button.text = ""

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and is_open:
			toggle()
