## Vampire Game (Godot)

This repo is scaffolded as a **Godot 4.5.1 (3D)** project.

### Open & run

- Install Godot 4.x
- Open the project by selecting this folder (it contains `project.godot`)
- Press **Play** (the main scene is `res://scenes/Main.tscn`)
- Press **Esc** to quit (mapped to `ui_cancel`)

### Controls (starter)

- **WASD / Arrow Keys**: move
- **Mouse**: look
- **Space**: jump
- **Shift**: sprint

### Project layout

- `scenes/`: `.tscn` scenes (starting with `Main.tscn`)
- `scripts/`: GDScript files
- `assets/`: art/audio/etc.

### Procedural boat model (Blender)

This repo includes a Blender Python script that generates a simple 3D boat (hull + deck, optional cabin/mast) and can export it as `.glb` for Godot.

Generate + export (headless):

```bash
blender --background --factory-startup --python tools/blender_generate_boat.py -- \
  --length 8 --beam 2.2 --draft 0.9 --stations 28 --segments 18 \
  --cabin --mast \
  --output /absolute/path/to/boat.glb --export_apply_modifiers
```


