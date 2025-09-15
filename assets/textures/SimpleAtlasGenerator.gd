@tool
extends EditorScript

func _run():
	create_simple_atlas()

func create_simple_atlas():
	var atlas_size = 256
	var block_size = 16
	
	var image = Image.create(atlas_size, atlas_size, false, Image.FORMAT_RGB8)
	image.fill(Color.MAGENTA)  # Debug background
	
	# Block colors (simple solid colors for now)
	var block_colors = [
		Color(0.2, 0.7, 0.2),   # Grass top - (0,0)
		Color(0.4, 0.3, 0.2),   # Grass side - (1,0)
		Color(0.5, 0.35, 0.2),  # Dirt - (2,0)
		Color(0.5, 0.5, 0.5),   # Stone - (3,0)
		Color(0.9, 0.85, 0.5),  # Sand - (0,1)
		Color(0.6, 0.4, 0.2),   # Wood top - (1,1)
		Color(0.4, 0.25, 0.1),  # Wood side - (2,1)
		Color(0.1, 0.5, 0.1),   # Leaves - (3,1)
	]
	
	# Position mapping
	var positions = [
		Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(3, 0),
		Vector2(0, 1), Vector2(1, 1), Vector2(2, 1), Vector2(3, 1)
	]
	
	# Fill each block texture
	for i in range(block_colors.size()):
		var color = block_colors[i]
		var pos = positions[i]
		
		var start_x = int(pos.x * block_size)
		var start_y = int(pos.y * block_size)
		
		# Fill block area with some simple pattern
		for x in range(block_size):
			for y in range(block_size):
				# Add simple noise pattern
				var noise = sin(x * 0.5) * cos(y * 0.5) * 0.1
				var final_color = Color(
					color.r + noise,
					color.g + noise,
					color.b + noise
				)
				image.set_pixel(start_x + x, start_y + y, final_color)
	
	# Save as PNG
	var result = image.save_png("res://assets/textures/block_atlas.png")
	if result == OK:
		print("Atlas créé avec succès: res://assets/textures/block_atlas.png")
		
		# Also create as ImageTexture resource
		var texture = ImageTexture.new()
		texture.set_image(image)
		ResourceSaver.save(texture, "res://assets/textures/block_atlas.tres")
		print("Texture resource créée: res://assets/textures/block_atlas.tres")
	else:
		print("Erreur lors de la création de l'atlas: ", result)