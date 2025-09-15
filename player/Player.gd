class_name Player
extends CharacterBody3D

const SPEED = 4.5
const JUMP_VELOCITY = 6  # Just enough to jump 1 block (1 meter)
const MOUSE_SENSITIVITY = 0.002
const REACH_DISTANCE = 3.0
const ACCELERATION = 10.0  # For snappier movement
const FRICTION = 10.0  # For quicker stops

var gravity = 20.0  # Increased gravity for more realistic jumps
var camera: Camera3D
var raycast: RayCast3D
var world: World
var selected_block_type: Block.BlockType = Block.BlockType.DIRT
var block_highlight: MeshInstance3D
var can_place_block: bool = true
var inventory: Inventory
var inventory_ui: InventoryUI
var hotbar: Hotbar

func _ready():
	# Create collision shape for the player
	var collision_shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	collision_shape.shape = capsule
	collision_shape.position = Vector3(0, 0.9, 0)
	add_child(collision_shape)
	
	# Create camera
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.5, 0)
	camera.fov = 75
	add_child(camera)
	
	# Create raycast for block interaction
	raycast = RayCast3D.new()
	raycast.target_position = Vector3(0, 0, -REACH_DISTANCE)
	raycast.collision_mask = 1
	raycast.enabled = true
	raycast.hit_from_inside = true  # Allow hitting from inside colliders
	raycast.collide_with_areas = false
	raycast.collide_with_bodies = true
	camera.add_child(raycast)
	
	# Create block highlight
	create_block_highlight()
	
	# Initialize inventory
	inventory = Inventory.new()
	inventory_ui = InventoryUI.new()
	hotbar = Hotbar.new()
	
	# Add some initial items for testing
	inventory.add_item(Block.BlockType.DIRT, 10)
	inventory.add_item(Block.BlockType.STONE, 5)
	inventory.add_item(Block.BlockType.WOOD, 3)
	
	# Connect inventory UI signals
	inventory_ui.slot_clicked.connect(_on_inventory_slot_clicked)
	inventory_ui.close_requested.connect(_on_inventory_closed)
	inventory_ui.item_dragged.connect(_on_inventory_item_dragged)
	
	# Connect hotbar signals
	hotbar.slot_selected.connect(_on_hotbar_slot_selected)
	hotbar.item_changed.connect(_on_hotbar_item_changed)
	hotbar.item_dropped_to_inventory.connect(_on_hotbar_item_dropped_to_inventory)
	
	# Wait for next frame to ensure UI is ready before setup
	await get_tree().process_frame
	inventory_ui.setup_inventory(inventory)
	
	# Add inventory UI to the scene
	setup_inventory_ui_in_scene()
	
	# Add hotbar to the scene
	setup_hotbar_in_scene()
	
	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func create_block_highlight():
	block_highlight = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.01, 1.01, 1.01)
	block_highlight.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	block_highlight.material_override = material
	block_highlight.visible = false
	
	if get_parent():
		get_parent().add_child(block_highlight)

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get input direction
	var input_dir = Vector2()
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	
	# Calculate movement direction
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		# Snappier acceleration
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION * delta)
	else:
		# Snappier deceleration (more Minecraft-like)
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0, FRICTION * delta)
	
	move_and_slide()
	
	# Update block interaction
	update_block_interaction()

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Block destruction (left click)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			destroy_block()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			place_block()
	
	# Inventory toggle
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_I:
			toggle_inventory()

func update_block_interaction():
	if not world:
		return
	
	var target_info = find_target_block_with_face()
	
	if target_info.has("block_position") and block_highlight:
		var block_pos = target_info.block_position
		block_highlight.visible = true
		block_highlight.position = block_pos + Vector3(0.5, 0.5, 0.5)
		
		# Check if we can place a block
		if target_info.has("place_position"):
			var place_pos = target_info.place_position
			var player_block_pos = world.world_to_block_position(global_position)
			var player_head_pos = world.world_to_block_position(global_position + Vector3(0, 1, 0))
			
			can_place_block = place_pos != Vector3(player_block_pos) and place_pos != Vector3(player_head_pos)
		else:
			can_place_block = false
	else:
		if block_highlight:
			block_highlight.visible = false
		can_place_block = false

func destroy_block():
	if not world:
		return
	
	var target_block = find_target_block()
	if target_block.has("position"):
		var block_type = target_block.type
		print("Destroying block at: ", target_block.position, " type: ", block_type)
		world.set_block_at_world_position(target_block.position, Block.BlockType.AIR)
		
		# Add destroyed block to inventory
		if block_type != Block.BlockType.AIR:
			add_item_to_inventory(block_type, 1)
	else:
		print("No block found to destroy")

func find_target_block() -> Dictionary:
	var start = camera.global_position
	var direction = -camera.global_transform.basis.z
	var step_size = 0.1
	var max_distance = REACH_DISTANCE
	
	print("Starting raycast from: ", start, " direction: ", direction)
	
	var current_pos = start
	for i in range(int(max_distance / step_size)):
		current_pos += direction * step_size
		
		var block_pos = world.world_to_block_position(current_pos)
		var block_type = world.get_block_at_world_position(current_pos)
		
		# Debug: print every few steps
		if i % 10 == 0:
			print("Step ", i, ": pos ", current_pos, " -> block pos ", block_pos, " -> type ", block_type)
		
		if block_type != Block.BlockType.AIR:
			print("Found solid block at step ", i, ": pos ", current_pos, " -> block pos ", block_pos, " -> type ", block_type)
			return {"position": Vector3(block_pos), "type": block_type}
	
	print("No solid block found in ", int(max_distance / step_size), " steps")
	return {}

func place_block():
	if not world or not can_place_block:
		return
	
	var target_info = find_target_block_with_face()
	if target_info.has("place_position"):
		var place_pos = target_info.place_position
		var player_block_pos = world.world_to_block_position(global_position)
		var player_head_pos = world.world_to_block_position(global_position + Vector3(0, 1, 0))
		
		# Can't place where the player is standing
		if place_pos != Vector3(player_block_pos) and place_pos != Vector3(player_head_pos):
			# Check if player has the block in hotbar
			var selected_item = hotbar.get_selected_item()
			if selected_item != null and not selected_item.is_empty():
				print("Placing block at: ", place_pos, " type: ", Block.new(selected_item.block_type).block_name)
				world.set_block_at_world_position(place_pos, selected_item.block_type)
				
				# Remove block from hotbar
				selected_item.quantity -= 1
				if selected_item.quantity <= 0:
					hotbar.set_item(hotbar.selected_slot, null)
				else:
					hotbar.update_slot_display(hotbar.selected_slot)
			else:
				print("No item in selected hotbar slot!")

func find_target_block_with_face() -> Dictionary:
	var start = camera.global_position
	var direction = -camera.global_transform.basis.z
	var step_size = 0.05
	var max_distance = REACH_DISTANCE
	
	var previous_pos = start
	var current_pos = start
	
	for i in range(int(max_distance / step_size)):
		current_pos += direction * step_size
		
		var block_type = world.get_block_at_world_position(current_pos)
		
		if block_type != Block.BlockType.AIR:
			var block_pos = world.world_to_block_position(current_pos)
			var place_pos = world.world_to_block_position(previous_pos)
			return {
				"block_position": Vector3(block_pos), 
				"block_type": block_type,
				"place_position": Vector3(place_pos)
			}
		
		previous_pos = current_pos
	
	return {}

func toggle_inventory():
	inventory_ui.toggle()

func _on_inventory_slot_clicked(slot_index: int):
	var item = inventory.get_item(slot_index)
	if item != null and not item.is_empty():
		selected_block_type = item.block_type
		print("Selected from inventory: ", item.get_block_name())

func _on_inventory_closed():
	# Called when inventory is closed
	pass

func add_item_to_inventory(block_type: Block.BlockType, quantity: int = 1):
	return inventory.add_item(block_type, quantity)

func setup_hotbar_in_scene():
	# Find the Main node and add hotbar to its canvas layer
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node == null:
		var current = get_parent()
		while current != null:
			if current.has_method("create_ui"):
				main_node = current
				break
			current = current.get_parent()
	
	if main_node and main_node.has_method("get") and main_node.canvas_layer:
		main_node.canvas_layer.add_child(hotbar)
		print("Hotbar added to canvas layer")

func _on_hotbar_slot_selected(slot_index: int):
	var item = hotbar.get_item(slot_index)
	if item != null and not item.is_empty():
		selected_block_type = item.block_type
		print("Selected from hotbar: ", item.get_block_name())
	else:
		# If empty slot, keep current selection but update to show it's empty
		print("Empty hotbar slot selected")

func _on_hotbar_item_changed(slot_index: int, item: InventoryItem):
	# Update selection if this is the current slot
	if slot_index == hotbar.selected_slot:
		_on_hotbar_slot_selected(slot_index)

func _on_inventory_item_dragged(from_slot: int, item: InventoryItem):
	# Try to add item to hotbar
	if hotbar.try_add_item_from_inventory(item):
		# Remove one item from inventory
		inventory.remove_item(from_slot, 1)
		inventory_ui.update_display()
		print("Moved item from inventory to hotbar")
	else:
		print("Hotbar is full!")

func _on_hotbar_item_dropped_to_inventory(slot_index: int, item: InventoryItem):
	# Add item back to inventory
	if inventory.add_item(item.block_type, item.quantity):
		inventory_ui.update_display()
		print("Moved item from hotbar to inventory")
	else:
		# If inventory is full, keep in hotbar
		hotbar.set_item(slot_index, item)
		print("Inventory is full!")

func setup_inventory_ui_in_scene():
	# Find the Main node and add inventory UI to its canvas layer
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node == null:
		# Try to find Main by going up the tree
		var current = get_parent()
		while current != null:
			if current.has_method("create_ui"):  # Main has create_ui method
				main_node = current
				break
			current = current.get_parent()
	
	if main_node and main_node.has_method("get") and main_node.canvas_layer:
		main_node.canvas_layer.add_child(inventory_ui)
		print("Inventory UI added to canvas layer")
