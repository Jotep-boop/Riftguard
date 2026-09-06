# Riftguard

A single-player maze tower-defense game: reshape the crossing, combine magical defenses, and survive the rift. Original procedural geometry and synthesized audio; no third-party art assets.

## Strategic Replay milestone

One complete, restartable match with **six tactical waves**, **three tower roles with two exclusive upgrade branches each**, scouts/runners/brutes and a distinct **Rift Warden finale**, salvage, selling, gate lives and measured match results. Build time is unlimited between waves. Construction remains available during combat; sealing the route makes enemies breach blocking towers rather than become stuck.

### Play

Open `project.godot` in **Godot 4.7.2 stable** (compatible 4.7.x), then F5. The fixed logical canvas is 1280×720 and scales with the window. No install-time dependencies or downloads are needed beyond Godot.

1. Start with **240 salvage and 12 gate lives**. Select a tower, then click an empty cell near the route.
2. Combine Arc's focused damage, Nova's clustered damage and Frost's slowdown. Towers also reshape the maze.
3. Press **Space** when ready. Each ordinary enemy escaping costs one life (the final Warden costs four); each kill pays salvage. Clearing a wave pays **30 salvage**.
4. Upgrade/rebuild between waves. Clear wave six with lives remaining to win.

| Tower | Cost | Range | Role |
|---|---:|---:|---|
| Arc | 45 | **3.0** | 25 damage every 0.65 s |
| Nova | 65 | 2.7 | 20 damage every 1.1 s, 1.3-cell splash |
| Frost | 55 | 3.0 | 8 damage every 0.85 s, 50% movement slow for 1.6 s |

### Choose your upgrade path

Select a tower and press **U** to inspect two alternatives **without spending**. Click a choice or press **Q / E**. **Esc** cancels. The first upgrade costs **35**, locks the branch and reaches level 2; **U** then reinforces that same branch for **70**, maximum level 3. Every level adds 65% of base damage and 35 maximum tower health, fully repairing it. **Range, targeting priority and firing cadence never change.** The branch multipliers below apply after level damage scaling.

| Tower | Q: focused option | E: coverage option |
|---|---|---|
| Arc | **Lance:** full damage; impact arrives in 0.09s instead of 0.18s | **Chain:** 60% damage per hit; one jump to the nearest living neighbor within 1.8 cells of the impact target |
| Nova | **Blast:** full damage; compact 1.3-cell splash | **Wide:** 70% damage; 2.2-cell splash |
| Frost | **Deep:** single target slowed 50% for 3.2s | **Coldfront:** 1.3-cell splash, each target slowed 50% for 1.6s |

Selling returns floor(70% of total investment), including upgrades; sell and rebuild to change a locked branch. Destroyed towers pay no refund. Slow refreshes duration, never stacks intensity. All shots resolve on impact and fizzle if their primary target has already died or escaped. Branch properties are captured at fire time, so upgrading or selling cannot rewrite an in-flight shot.

### Read the wave, then adapt

The preview gives the **actual composition, spawn spacing and tactical hint** for the next wave (current wave during combat).

1. **First contact:** six scouts, 0.72s spacing.
2. **Slipstream:** six runners and two scouts, 0.48s spacing.
3. **The gathering:** twelve scouts packed at 0.24s spacing.
4. **Iron procession:** six brutes spaced at 1.25s.
5. **Crosscurrent:** four brutes, two scouts and four runners, 0.55s spacing.
6. **The Rift Warden:** two brutes and six runner escorts with one crowned Warden, 0.60s spacing. The Warden has 1600 health in this wave, moves at 0.65 cells/s, deals 50 breach damage every 0.75s, costs four gate lives if it escapes and rewards 80 salvage if killed. Frost slows it by 25%, not 50%; it is never immune to targeting or damage.

Victory/defeat results show actual kills/escapes, gate lives, combat simulation time (excludes build/pause time), spending/refunds, salvage left, towers breached, damage dealt by role (excluding overkill), and a per-wave ledger. A lost wave is marked incomplete. **Defend again** or **R** resets the entire match and its statistics, ready to compare another strategy against the same authored waves. There is no fabricated score or persistent progression.

### Controls

- **1 / 2 / 3** or bottom buttons: select Arc / Nova / Frost.
- **LMB:** build on empty cell; select an existing tower.
- **Hover:** projected range and legal/illegal placement feedback.
- **U:** open branch choices / reinforce chosen branch. **Q / E:** choose while the panel is open; **Esc:** cancel.
- **X:** sell selected tower. **RMB:** sell hovered tower.
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

Runs import, the original 24 rule tests, expanded role/economy/lifecycle assertions, branch impact/safety tests, complete matches with both branch sets, stationary-targeting and chained-breach regressions, scene/HUD/input and full-results bounds checks, main launch and Git whitespace checks. The runner rejects runtime errors and warnings even when Godot exits zero.

Both deterministic branch strategies win all six waves on the real starting budget; the undefended fixture loses and restarts cleanly. See `VERIFICATION.md` for exact output and remaining QA limitations. Headless verification is **not visual or audio approval**.

## Scope

This is an approachable complete match, not a campaign or finished commercial release. No multiplayer, persistent progression, accounts, licensed assets or paid services. Internal changes stay small and test-driven; user deliveries are integrated playable milestones rather than individual micro-features.
