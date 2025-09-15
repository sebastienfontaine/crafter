@tool  # Allows running in editor
class_name TextureGenerator
extends EditorScript

const ATLAS_SIZE = 256
const BLOCK_SIZE = 16
const BLOCKS_PER_ROW = ATLAS_SIZE / BLOCK_SIZE

# Generate a simple texture atlas
func generate_atlas():
	var image = Image.create(ATLAS_SIZE, ATLAS_SIZE, false, Image.FORMAT_RGB8)
	image.fill(Color.MAGENTA)  # Magenta background for debugging
	
	# Generate block textures
	generate_grass_top(image, 0, 0)
	generate_grass_side(image, 1, 0)
	generate_dirt(image, 2, 0)
	generate_stone(image, 3, 0)
	generate_sand(image, 0, 1)
	generate_wood_top(image, 1, 1)
	generate_wood_side(image, 2, 1)
	generate_leaves(image, 3, 1)
	
	# Save the image
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	ResourceSaver.save(texture, "res://assets/textures/block_atlas.tres")
	image.save_png("res://assets/textures/block_atlas.png")
	
	print("Texture atlas generated!")

func generate_grass_top(image: Image, grid_x: int, grid_y: int):
	var start_x = grid_x * BLOCK_SIZE
	var start_y = grid_y * BLOCK_SIZE
	
	# Green base with some variation
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var noise_val = sin(x * 0.5) * cos(y * 0.5) * 0.1
			var green_val = 0.3 + noise_val
			image.set_pixel(start_x + x, start_y + y, Color(0.1, green_val, 0.1))

func generate_grass_side(image: Image, grid_x: int, grid_y: int):
	var start_x = grid_x * BLOCK_SIZE
	var start_y = grid_y * BLOCK_SIZE
	
	# Green top part, brown bottom part
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			if y < 3:  # Top 3 pixels green
				image.set_pixel(start_x + x, start_y + y, Color(0.15, 0.4, 0.15))
			else:  # Rest brown (dirt)
				var noise_val = sin(x * 0.3) * 0.05
				image.set_pixel(start_x + x, start_y + y, Color(0.4 + noise_val, 0.25, 0.15))

func generate_dirt(image: Image, grid_x: int, grid_y: int):
	var start_x = grid_x * BLOCK_SIZE
	var start_y = grid_y * BLOCK_SIZE
	
	# Brown with variation
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var noise_val = sin(x * 0.4) * cos(y * 0.4) * 0.1
			image.set_pixel(start_x + x, start_y + y, Color(0.4 + noise_val, 0.25, 0.15))

func generate_stone(image: Image, grid_x: int, grid_y: int):
	var start_x = grid_x * BLOCK_SIZE
	var start_y = grid_y * BLOCK_SIZE
	
	# Gray with variation
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var noise_val = sin(x * 0.6) * cos(y * 0.6) * 0.1
			var gray_val = 0.4 + noise_val
			image.set_pixel(start_x + x, start_y + y, Color(gray_val, gray_val, gray_val))

func generate_sand(image: Image, grid_x: int, grid_y: int):
	var start_x = grid_x * BLOCK_SIZE
	var start_y = grid_y * BLOCK_SIZE
	
	# Yellow/beige
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var noise_val = sin(x * 0.3) * cos(y * 0.3) * 0.05
			image.set_pixel(start_x + x, start_y + y, Color(0.8 + noise_val, 0.7, 0.4))

func generate_wood_top(image: Image, grid_x: int, grid_y: int):
	var start_x = grid_x * BLOCK_SIZE
	var start_y = grid_y * BLOCK_SIZE
	
	# Wood rings pattern
	var center = BLOCK_SIZE / 2.0
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var distance = Vector2(x - center, y - center).length()
			var ring_pattern = sin(distance * 0.8) * 0.1
			image.set_pixel(start_x + x, start_y + y, Color(0.4 + ring_pattern, 0.25, 0.15))

func generate_wood_side(image: Image, grid_x: int, grid_y: int):
	var start_x = grid_x * BLOCK_SIZE
	var start_y = grid_y * BLOCK_SIZE
	
	# Vertical grain
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var grain = sin(x * 0.5) * 0.05
			image.set_pixel(start_x + x, start_y + y, Color(0.35 + grain, 0.2, 0.1))

func generate_leaves(image: Image, grid_x: int, grid_y: int):
	var start_x = grid_x * BLOCK_SIZE
	var start_y = grid_y * BLOCK_SIZE
	
	# Dark green with random pattern
	for x in range(BLOCK_SIZE):
		for y in range(BLOCK_SIZE):
			var pattern = sin(x * 0.8) * cos(y * 0.8) * 0.1
			image.set_pixel(start_x + x, start_y + y, Color(0.1, 0.3 + pattern, 0.1))

func _run():
	generate_atlas()