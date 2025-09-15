# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 game project named "crafter" - a Minecraft-like voxel-based sandbox game. The project uses Godot's mobile rendering method for optimal performance with voxel rendering.

## Development Commands

### Running the Project
```bash
# Open project in Godot Editor
godot project.godot

# Run the game directly
godot --path . 

# Run in debug mode
godot --path . --debug
```

### Exporting the Project
```bash
# Export for specific platform (requires export templates)
godot --export-release "platform_name" output_file
```

## Project Structure

- **project.godot** - Main Godot project configuration file
- **.godot/** - Auto-generated Godot cache and import files (ignored by git)
- **icon.svg** - Project icon file
- **world/** - World generation and chunk management
- **blocks/** - Block types, textures, and properties
- **player/** - Player controller, inventory, and interactions
- **ui/** - User interface (inventory, crafting, menus)
- **systems/** - Core systems (saving, loading, networking)
- **assets/** - Textures, models, sounds

## Voxel Game Architecture

### Core Systems
- **Chunk System**: World divided into chunks (e.g., 16x16x16 blocks) for efficient rendering and memory management
- **Block Registry**: Centralized system for block types, properties, and behaviors
- **Mesh Generation**: Dynamic mesh generation for voxel chunks using greedy meshing or similar optimization
- **World Generation**: Procedural terrain generation using noise functions (Perlin, Simplex)
- **Physics**: Collision detection for voxel world using Godot's physics engine

### Key Technical Considerations
- Use MultiMesh for rendering multiple blocks efficiently
- Implement LOD (Level of Detail) system for distant chunks
- Use threading for chunk generation to avoid frame drops
- Implement chunk pooling to reuse memory
- Use spatial indexing for efficient block lookups

## Godot-Specific Development Notes

- Use Node3D as base for world and chunk nodes
- GridMap can be used for prototyping but custom mesh generation is preferred for optimization
- Use StaticBody3D with generated collision shapes for chunk physics
- CharacterBody3D for player controller with custom movement logic
- Use Godot's signal system for block interactions and events
- Follow Godot naming conventions: snake_case for variables/functions, PascalCase for classes/nodes

## Performance Guidelines

- Target 60 FPS with reasonable view distance (8-12 chunks)
- Optimize chunk mesh generation (greedy meshing, face culling)
- Use occlusion culling for chunks behind the player
- Implement frustum culling to avoid rendering off-screen chunks
- Consider using compute shaders for complex world generation

## File Format Preferences

- Use text-based formats (.tscn, .tres) over binary formats for better version control
- Maintain UTF-8 encoding for all text files (as specified in .editorconfig)
- Store world data in custom binary format for efficient saving/loading
- Use texture atlases for block textures to reduce draw calls