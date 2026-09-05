# Riftguard

A modern perspective-styled 2D maze tower-defense game inspired by the social, strategic joy of classic Warcraft III mauls.

## Current milestone: Combat Slice

The current playable slice proves the maze and first combat loop:

- perspective-projected grid rendered in 2D
- enemy route from rift to gate
- build preview and grid interaction
- path validation before construction
- impossible placements are rejected
- placed structures automatically attack enemies in range
- visible projectiles, enemy health, death feedback and kill gold
- tower range preview and visible debug route

## Controls

- **Left mouse:** place an arc tower
- **Right mouse:** remove a tower
- **Hover a tower:** show its attack range
- **R:** clear all towers
- **D:** toggle route visualization

## Open in Godot

Use Godot **4.7.2 stable** or another compatible 4.7.x release. Import `project.godot`, then press **F6/F5** to run.

## Test headlessly

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

## Project principles

- `main` remains playable.
- Simulation state is separate from rendering.
- New game rules are developed test-first.
- Towers, enemies and waves will be data-driven.
- Multiplayer is postponed until the single-player loop is fun.
