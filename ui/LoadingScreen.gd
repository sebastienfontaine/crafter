class_name LoadingScreen
extends Control

signal loading_complete()

var progress_bar: ProgressBar
var status_label: Label
var title_label: Label

var total_chunks: int = 0
var loaded_chunks: int = 0

func _init():
	name = "LoadingScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready():
	create_loading_ui()

func create_loading_ui():
	# Semi-transparent dark background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Main container
	var container = VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	container.custom_minimum_size = Vector2(400, 200)
	add_child(container)
	
	# Game title
	title_label = Label.new()
	title_label.text = "🔮 CRAFTER"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title_label)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 40)
	container.add_child(spacer1)
	
	# Status text
	status_label = Label.new()
	status_label.text = "Initializing world generation..."
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(status_label)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(350, 30)
	progress_bar.value = 0
	progress_bar.max_value = 100
	container.add_child(progress_bar)
	
	# Progress percentage
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.text = "0%"
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(progress_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	container.add_child(spacer2)
	
	# Flavor text
	var flavor = Label.new()
	flavor.text = "Generating crystalline terrain..."
	flavor.add_theme_font_size_override("font_size", 12)
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.modulate = Color(0.8, 0.8, 0.8)
	container.add_child(flavor)

func start_loading(chunk_count: int):
	total_chunks = chunk_count
	loaded_chunks = 0
	update_progress()
	visible = true

func update_chunk_progress(chunks_loaded: int):
	loaded_chunks = chunks_loaded
	update_progress()

func update_status(text: String):
	if status_label:
		status_label.text = text

func update_progress():
	if not progress_bar:
		return
	
	var percentage = 0.0
	if total_chunks > 0:
		percentage = (float(loaded_chunks) / float(total_chunks)) * 100.0
	
	progress_bar.value = percentage
	
	# Find the progress label by walking through children
	var container = get_children()[1] if get_child_count() > 1 else null
	var progress_label = null
	if container:
		for child in container.get_children():
			if child.name == "ProgressLabel":
				progress_label = child
				break
	
	if progress_label:
		progress_label.text = str(int(percentage)) + "%"
	
	# Update status based on progress
	if percentage < 30:
		update_status("Generating terrain heightmaps...")
	elif percentage < 60:
		update_status("Placing blocks and structures...")
	elif percentage < 90:
		update_status("Creating chunk meshes...")
	else:
		update_status("Finalizing world...")
	
	# Complete when 100%
	if percentage >= 100:
		complete_loading()

func complete_loading():
	update_status("World generation complete!")
	
	# Emit signal immediately to continue game flow
	loading_complete.emit()
	
	# Fade out effect after emitting signal
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5)
	tween.tween_callback(func():
		queue_free()
	)
