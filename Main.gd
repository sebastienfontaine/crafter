extends Node3D

var world: World
var player: Player
var sun_light: DirectionalLight3D
var coords_indicator: Label
var fps_indicator: Label
var canvas_layer: CanvasLayer
var loading_screen: LoadingScreen

func _ready():
	# Force regenerate texture atlas with new UV settings
	generate_texture_atlas()
	
	# Wait a frame to ensure atlas is properly saved
	await get_tree().process_frame
	
	# Create and show loading screen first
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	loading_screen = LoadingScreen.new()
	canvas_layer.add_child(loading_screen)
	loading_screen.loading_complete.connect(_on_loading_complete)
	
	# Calculate total chunks to show in progress
	var render_distance = 2  # Should match World's render_distance
	var total_chunks = (render_distance * 2 + 1) * (render_distance * 2 + 1)
	loading_screen.start_loading(total_chunks)
	
	# Start world generation asynchronously
	start_world_generation()

func start_world_generation():
	# Create world
	world = World.new()
	add_child(world)
	
	# Calculate spawn position with proper terrain height
	var spawn_x = 8.0
	var spawn_z = 8.0
	var terrain_height = world.chunk_manager.world_generator.get_terrain_height(spawn_x, spawn_z)
	var spawn_position = Vector3(spawn_x, terrain_height + 2, spawn_z)
	
	# Create player but don't add to world yet
	player = Player.new()
	player.position = spawn_position
	player.world = world
	# Don't set world.player yet to avoid infinite loops
	
	# Connect progress signal
	world.chunk_generation_progress.connect(_on_chunk_generation_progress)
	
	# Generate initial chunks around spawn
	await world.generate_chunks_around_position_async(spawn_position)
	
	# Now set the player reference after generation is complete
	world.player = player

func _on_chunk_generation_progress(chunks_loaded: int, total_chunks: int):
	if loading_screen:
		loading_screen.update_chunk_progress(chunks_loaded)

func _on_loading_complete():
	# Hide loading screen and finish initialization
	if loading_screen:
		loading_screen.hide_loading()
	
	_finish_initialization()

func _finish_initialization():
	# Add player to scene
	add_child(player)
	
	# Create sun light
	sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-45, -45, 0)
	sun_light.light_energy = 1.0
	sun_light.shadow_enabled = true
	add_child(sun_light)
	
	# Add ambient light with WorldEnvironment node
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.3
	env.fog_enabled = true
	env.fog_density = 0.005
	
	world_env.environment = env
	add_child(world_env)
	
	# Create UI (reuse the existing canvas_layer)
	create_ui()

func create_ui():
	# Canvas layer already exists from loading screen, just reuse it
	
	# Crosshair
	var crosshair = Control.new()
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	canvas_layer.add_child(crosshair)
	
	var h_line = ColorRect.new()
	h_line.color = Color.WHITE
	h_line.size = Vector2(20, 2)
	h_line.position = Vector2(-10, -1)
	crosshair.add_child(h_line)
	
	var v_line = ColorRect.new()
	v_line.color = Color.WHITE
	v_line.size = Vector2(2, 20)
	v_line.position = Vector2(-1, -10)
	crosshair.add_child(v_line)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "WASD: Move | Space: Jump | Mouse: Look
Left Click: Break Block | Right Click: Place Block
1-7: Select Block Type | ESC: Toggle Mouse"
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.position = Vector2(10, 10)
	canvas_layer.add_child(instructions)
	
	# Block type indicator
	var block_indicator = Label.new()
	block_indicator.name = "BlockIndicator"
	block_indicator.text = "Selected: Dirt"
	block_indicator.add_theme_font_size_override("font_size", 16)
	block_indicator.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	block_indicator.position = Vector2(10, -40)
	canvas_layer.add_child(block_indicator)
	
	# Player coordinates indicator
	coords_indicator = Label.new()
	coords_indicator.name = "CoordsIndicator"
	coords_indicator.text = "X: 0 Y: 0 Z: 0"
	coords_indicator.add_theme_font_size_override("font_size", 14)
	coords_indicator.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	coords_indicator.position = Vector2(-120, 10)
	canvas_layer.add_child(coords_indicator)
	
	# FPS indicator
	fps_indicator = Label.new()
	fps_indicator.name = "FPSIndicator"
	fps_indicator.text = "FPS: 60"
	fps_indicator.add_theme_font_size_override("font_size", 16)
	fps_indicator.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fps_indicator.position = Vector2(-80, 35)
	canvas_layer.add_child(fps_indicator)

func _process(_delta):
	# Update block indicator
	if player:
		var indicator = get_node_or_null("CanvasLayer/BlockIndicator")
		if indicator:
			var block = Block.new(player.selected_block_type)
			indicator.text = "Selected: " + block.block_name
	
	# Update player coordinates indicator  
	if coords_indicator and player:
		var pos = player.global_position
		coords_indicator.text = "X: " + str(snapped(pos.x, 0.1)) + " Y: " + str(snapped(pos.y, 0.1)) + " Z: " + str(snapped(pos.z, 0.1))
	
	# Update FPS indicator
	if fps_indicator:
		fps_indicator.text = "FPS: " + str(Engine.get_frames_per_second())
	
	# Update chunks around player
	if world and player:
		world.update_chunks_around_player()

func generate_texture_atlas():
	# Clear existing atlas to ensure regeneration with new settings
	if FileAccess.file_exists("res://assets/textures/block_atlas.tres"):
		DirAccess.remove_absolute("res://assets/textures/block_atlas.tres")
	if FileAccess.file_exists("res://assets/textures/block_atlas.png"):
		DirAccess.remove_absolute("res://assets/textures/block_atlas.png")
	
	var atlas_size = 64   # 4x4 grid
	var block_size = 16   # Standard block size
	
	var image = Image.create(atlas_size, atlas_size, false, Image.FORMAT_RGB8)
	image.fill(Color.BLACK)  # Black background instead of magenta
	
	# Block colors matching our current system
	var blocks = [
		{"color": Color(0.2, 0.7, 0.2), "pos": Vector2(0, 0)},  # Grass top
		{"color": Color(0.4, 0.3, 0.2), "pos": Vector2(1, 0)},  # Grass side  
		{"color": Color(0.5, 0.35, 0.2), "pos": Vector2(2, 0)}, # Dirt
		{"color": Color(0.5, 0.5, 0.5), "pos": Vector2(3, 0)},  # Stone
		{"color": Color(0.9, 0.85, 0.5), "pos": Vector2(0, 1)}, # Sand
		{"color": Color(0.6, 0.4, 0.2), "pos": Vector2(1, 1)},  # Wood top
		{"color": Color(0.4, 0.25, 0.1), "pos": Vector2(2, 1)}, # Wood side
		{"color": Color(0.1, 0.5, 0.1), "pos": Vector2(3, 1)},  # Leaves
	]
	
	# Fill each block texture 
	for block in blocks:
		var start_x = int(block.pos.x * block_size)
		var start_y = int(block.pos.y * block_size)
		var color = block.color
		
		# Fill the entire block area (16x16) with color + simple pattern
		for x in range(block_size):
			for y in range(block_size):
				var noise = sin(x * 0.3) * cos(y * 0.3) * 0.05
				var final_color = Color(
					clamp(color.r + noise, 0, 1),
					clamp(color.g + noise, 0, 1),
					clamp(color.b + noise, 0, 1)
				)
				image.set_pixel(start_x + x, start_y + y, final_color)
		
	
	# Save as PNG and resource
	var result = image.save_png("res://assets/textures/block_atlas.png")
	if result == OK:
		var texture = ImageTexture.new()
		texture.set_image(image)
		ResourceSaver.save(texture, "res://assets/textures/block_atlas.tres")
