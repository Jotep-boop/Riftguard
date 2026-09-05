# Riftguard — Game Vision

## Player fantasy

Guard unstable rifts by constructing magical defenses that reshape the enemy route. The player should feel clever for designing an efficient maze and powerful when a carefully planned defense comes alive.

## Core loop

1. Inspect the next enemy wave.
2. Spend limited resources on towers and upgrades.
3. Shape a legal route through the build zone.
4. Survive the wave and study weak points.
5. Adapt the maze and grow a distinct defensive faction.

## Design pillars

### Readable strategy
The route, tower range, targeting and damage outcome must be understandable without consulting a spreadsheet.

### Satisfying impact
Placement, attacks, status effects and kills need layered audiovisual feedback.

### Meaningful factions
Each faction changes how the maze is planned; factions must not merely recolor equivalent towers.

## Scope guardrails

The first vertical slice contains one board, one faction, three tower roles and a short sequence of waves. No accounts, progression store, procedural campaign or network multiplayer before that slice is fun and stable.

## Blocking and breach behavior

Tower placement is unrestricted once tower health and enemy attacks exist. If construction seals every normal route, enemies identify a reachable breach point, advance to it and attack the blocking tower until a route opens. A blocked route is therefore a costly tactical choice, not an invalid input. The prototype may continue rejecting sealed routes until this complete feedback loop is implemented; it must never silently trap enemies.

## Presentation

Riftguard currently uses a 13-cell-long by 9-cell-wide logical board, viewed from a fixed high three-quarter angle along one long side. The rift and guarded exit remain centered on opposite 9-cell short sides, making the primary enemy flow read laterally across the screen. Grid rows widen mildly toward the camera to create depth without a 3D simulation. Height is communicated with silhouettes, vertical offsets, shadows, overlap sorting and effects.
