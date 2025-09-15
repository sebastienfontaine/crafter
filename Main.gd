extends Node3D

var world: World
var player: Player
var sun_light: DirectionalLight3D

func _ready():
	# Create world
	world = World.new()
	add_child(world)
	
	# Create player
	player = Player.new()
	player.position = Vector3(8, 60, 8)  # Start in middle of a chunk, high enough
	player.world = world
	world.player = player
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
	
	# Create UI
	create_ui()

func create_ui():
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
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

func _process(_delta):
	# Update block indicator
	if player:
		var indicator = get_node_or_null("CanvasLayer/BlockIndicator")
		if indicator:
			var block = Block.new(player.selected_block_type)
			indicator.text = "Selected: " + block.block_name
	
	# Update chunks around player
	if world and player:
		world.update_chunks_around_player()
