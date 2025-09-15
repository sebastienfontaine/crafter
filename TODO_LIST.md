# TODO LIST - Crafter Optimizations

## 🚀 Performance Optimizations

### High Priority (Major Performance Gains)

- [ ] **Compute Shaders for Mesh Generation**
  - Move mesh generation from CPU to GPU using compute shaders
  - Expected gain: 5-10x faster mesh generation
  - Implementation: Create `.glsl` compute shader for chunk meshing
  - Files to modify: `ChunkManager.gd`, create new `ChunkMeshGenerator.glsl`

- [ ] **Texture Atlas System**
  - Replace vertex colors with actual block textures
  - Use single texture atlas for all block types
  - Reduces draw calls significantly
  - Files to modify: `Chunk.gd`, `Block.gd`, create texture atlas image

- [ ] **Frustum Culling**
  - Don't render chunks outside camera view
  - Can save 50-70% of rendering when looking in one direction
  - Implementation: Check chunk visibility against camera frustum
  - Files to modify: `World.gd`, `Chunk.gd`

### Medium Priority (Moderate Performance Gains)

- [ ] **Level of Detail (LOD) System**
  - Reduce mesh complexity for distant chunks
  - Near: Full detail, Far: Lower resolution meshes
  - Files to modify: `ChunkManager.gd`, `Chunk.gd`

- [ ] **Occlusion Culling**
  - Don't render chunks behind other chunks
  - More complex but significant gains in dense worlds
  - Implementation: Raycast-based or portal system

- [ ] **Greedy Meshing Algorithm**
  - Combine adjacent faces of same block type into larger quads
  - Reduces vertex count by 60-80%
  - Files to modify: `ChunkManager.gd` mesh generation

### Low Priority (Quality of Life)

- [ ] **Chunk Pooling**
  - Reuse chunk objects instead of creating/destroying
  - Reduces garbage collection pauses
  - Files to modify: `World.gd`, `Chunk.gd`

- [ ] **Async Collision Shape Generation**
  - Generate collision shapes on separate thread
  - Currently blocks main thread during collision creation
  - Files to modify: `ChunkManager.gd`

## 🎨 Visual Enhancements

### High Priority

- [ ] **Block Texture Implementation**
  - Create texture atlas with different block textures
  - Grass top/side textures, stone, dirt, etc.
  - Replace current vertex color system

- [ ] **Ambient Occlusion**
  - Add subtle shadows at block corners
  - Makes world look more 3D and realistic
  - Can be computed during mesh generation

### Medium Priority

- [ ] **Dynamic Lighting System**
  - Light propagation through world
  - Torches, sunlight, etc.
  - Complex but adds lot to atmosphere

- [ ] **Biome System**
  - Different terrain types (desert, forest, mountains)
  - Varies block generation based on biome
  - Files to modify: `WorldGenerator.gd`

## 🎮 Gameplay Features

### High Priority

- [ ] **Inventory System**
  - Store picked up blocks
  - Block selection UI
  - Files: Create `Inventory.gd`, modify `Player.gd`, `UI`

- [ ] **Block Breaking Animation**
  - Cracks appear when breaking blocks
  - Visual feedback for destruction progress
  - Files to modify: `Player.gd`, create breaking effect

### Medium Priority

- [ ] **Sound Effects**
  - Block breaking/placing sounds
  - Footstep sounds
  - Background ambiance

- [ ] **Crafting System**
  - Combine blocks to create new items
  - Crafting table interface

- [ ] **Water & Liquids**
  - Flowing water simulation
  - Complex but very cool feature

## 🔧 Code Quality & Architecture

### High Priority

- [ ] **Error Handling**
  - Add proper error handling for chunk generation failures
  - Handle thread crashes gracefully
  - Files to modify: `ChunkManager.gd`, `World.gd`

- [ ] **Performance Profiling**
  - Add timing measurements for chunk operations
  - Identify actual bottlenecks
  - Create debug UI for performance stats

### Medium Priority

- [ ] **Save/Load System**
  - Save world state to disk
  - Load existing worlds
  - Files: Create `WorldSaveLoad.gd`

- [ ] **Multiplayer Foundation**
  - Network-ready architecture
  - Synchronized block changes
  - Very complex but future-proof

## 📊 Implementation Order Recommendation

1. **Texture Atlas** (biggest visual improvement)
2. **Frustum Culling** (immediate performance gain)
3. **Inventory System** (essential gameplay)
4. **Compute Shaders** (major performance boost, but complex)
5. **LOD System** (performance for large worlds)
6. **Greedy Meshing** (optimization)

## 🎯 Performance Targets

- **Target FPS**: 60 FPS stable
- **Render Distance**: 8-12 chunks (vs current 2)
- **Chunk Generation**: <5ms per chunk (vs current ~50ms)
- **Memory Usage**: <2GB for large worlds

## 📝 Notes

- Some optimizations require Godot 4.1+ features
- Compute shaders need OpenGL 4.3+ / Vulkan support
- Test on lower-end hardware before implementing complex features
- Always profile before and after optimizations
