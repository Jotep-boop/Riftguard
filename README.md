# Riftguard

A single-player maze tower-defense game: reshape the crossing, combine magical defenses, and survive the rift. Original procedural geometry and synthesized audio; no third-party art assets.

## Complete Match milestone

One complete, restartable match with **six finite waves**, **three tower roles**, **three enemy types**, salvage, upgrades, selling, gate lives, victory and defeat. Build time is unlimited between waves. Construction remains available during combat; sealing the route makes enemies breach blocking towers rather than become stuck.

### Play

Open `project.godot` in **Godot 4.7.2 stable** (compatible 4.7.x), then F5. The fixed logical canvas is 1280×720 and scales with the window. No install-time dependencies or downloads are needed beyond Godot.

1. Start with **240 salvage and 12 gate lives**. Select a tower, then click an empty cell near the route.
2. Combine Arc's focused damage, Nova's clustered damage and Frost's slowdown. Towers also reshape the maze.
3. Press **Space** when ready. Each enemy escaping costs one life; each kill pays salvage. Clearing a wave pays **30 salvage**.
4. Upgrade/rebuild between waves. Clear wave six with lives remaining to win.

| Tower | Cost | Range | Role |
|---|---:|---:|---|
| Arc | 45 | **3.0** | 25 damage every 0.65 s |
| Nova | 65 | 2.7 | 20 damage every 1.1 s, 1.3-cell splash |
| Frost | 55 | 3.0 | 8 damage every 0.85 s, 50% movement slow for 1.6 s |

Upgrade costs are **35**, then **70**, maximum level 3. Each level adds 65% of base damage and 35 tower maximum health, fully repairing the tower; range never changes. Selling returns floor(70% of total investment). Destroyed towers pay no refund. Slow refreshes duration, never stacks intensity. Nova splashes around a living target on impact; shots fizzle if their target has already died or escaped.

### Controls

- **1 / 2 / 3** or bottom buttons: select Arc / Nova / Frost.
- **LMB:** build on empty cell; select an existing tower.
- **Hover:** projected range and legal/illegal placement feedback.
- **U / X:** upgrade / sell selected tower. **RMB:** sell hovered tower.
- **Space:** launch next wave. **P:** pause/resume. **F:** 1× / 2× speed.
- **D:** route overlay. **M:** mute/unmute generated sound effects.
- **R:** immediately restart the whole match (not just clear the maze).

## Preserved rules

The board remains **13×9**, rift `(0,4)`, gate `(12,4)`, viewed high along the long side with left-to-right flow. Arc range remains exactly 3 cells. Breachers are ordinary targets and incoming projectiles retain impact timing; kills reward exactly once and stop demolition. Each enemy keeps its own route and replans from its current cell after topology changes; newly spawned enemies always start at the canonical rift. Placement cannot overlap enemies or their active movement destination. Build/sell changes never teleport enemies.

## Verification

```bash
python3 tools/verify.py
# Optional engine override:
GODOT=/path/to/godot python3 tools/verify.py
```

Runs import, the original 24 rule tests, expanded role/economy/lifecycle assertions, complete-match integration simulations, scene/HUD/input smoke checks, main launch and Git whitespace checks. The runner rejects runtime errors and warnings even when Godot exits zero.

The deterministic mixed-defense fixture wins all six waves on the real starting budget; the undefended fixture loses and restarts cleanly. See `VERIFICATION.md` for exact output and remaining QA limitations. Headless verification is **not visual or audio approval**.

## Scope

This is an approachable complete match, not a campaign or finished commercial release. No multiplayer, persistent progression, accounts, licensed assets or paid services. Internal changes stay small and test-driven; user deliveries are integrated playable milestones rather than individual micro-features.
