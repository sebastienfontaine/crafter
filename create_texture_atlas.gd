@tool
extends ScriptEditorPlugin

func create_atlas():
	var atlas_size = 256
	var block_size = 16
	
	var image = Image.create(atlas_size, atlas_size, false, Image.FORMAT_RGB8)
	image.fill(Color.MAGENTA)  # Debug background
	
	# Block colors and positions
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
	
	# Fill each 16x16 block
	for block in blocks:
		var start_x = int(block.pos.x * block_size)
		var start_y = int(block.pos.y * block_size)
		var color = block.color
		
		for x in range(block_size):
			for y in range(block_size):
				# Add simple pattern
				var noise = sin(x * 0.5) * cos(y * 0.5) * 0.1
				var final_color = Color(
					clamp(color.r + noise, 0, 1),
					clamp(color.g + noise, 0, 1),
					clamp(color.b + noise, 0, 1)
				)
				image.set_pixel(start_x + x, start_y + y, final_color)
	
	# Save PNG
	var result = image.save_png("res://assets/textures/block_atlas.png")
	if result == OK:
		print("Atlas PNG créé avec succès!")
		
		# Create ImageTexture resource
		var texture = ImageTexture.new()
		texture.set_image(image)
		ResourceSaver.save(texture, "res://assets/textures/block_atlas.tres")
		print("Texture resource créée!")
		return true
	else:
		print("Erreur lors de la création de l'atlas: ", result)
		return false

# Call this function to create the atlas
func _ready():
	if create_atlas():
		print("Texture atlas ready!")