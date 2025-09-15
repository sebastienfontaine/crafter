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
	
	# Block selection with number keys
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_7:
			var index = event.keycode - KEY_1 + 1
			if index < Block.BlockType.size():
				selected_block_type = index
				print("Selected block: ", Block.new(selected_block_type).block_name)

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
		print("Destroying block at: ", target_block.position, " type: ", target_block.type)
		world.set_block_at_world_position(target_block.position, Block.BlockType.AIR)
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
			print("Placing block at: ", place_pos, " type: ", Block.new(selected_block_type).block_name)
			world.set_block_at_world_position(place_pos, selected_block_type)

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
