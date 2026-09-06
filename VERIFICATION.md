# Complete Match verification

## Handoff

Feature branch `feature/complete-match`, based on clean `main` at `2ea3a1d`. Implementation is uncommitted and unpushed for independent parent review. Verified live repo `/home/hermes/projects/Riftguard`, host `hermes`, UID/GID 1001, Godot `4.7.2.stable.official.ed1daf0bf`.

## Automated gate

`python3 tools/verify.py` passes all six Godot checks and `git diff --check`. It checks exit status, rejects `SCRIPT ERROR`, `ERROR:` and warnings, and requires completion markers. No errors or warnings remain in the headless gate.

- Existing rules: `PASS: 24 tests` (including Arc 3-cell inclusive boundary, incoming breach hits, ordinary targeting and exactly-once death rewards).
- Role/economy/lifecycle suite: `Match assertions failed: 0; assertions executed: 23`.
- Integration: `Integration failures: 0; peak concurrent enemies: 6`.
- Scene: `PASS: match scene, camera, HUD, placement, active wave, restart`.
- Import and main launch exit 0.

Real-budget deterministic defense (four starting towers; affordable upgrades/reinforcements between waves):

| Wave | Outcome | Lives | Salvage at clear | Cumulative kills |
|---|---|---:|---:|---:|
| 1 | build | 12 | 120 | 6 |
| 2 | build | 12 | 125 | 14 |
| 3 | build | 12 | 156 | 21 |
| 4 | build | 12 | 170 | 31 |
| 5 | build | 12 | 178 | 41 |
| 6 | won | 12 | 277 | 53 |

Undefended simulation loses; restart resets budget, lives, enemies, board, wave state and pending events. Tests also cover splash limits, timed slow and real halved navigation speed, upgrade impact damage/cap, insufficient funds, invalid purchase atomicity, selling, live navigation invalidation without teleportation, two complete barriers, multi-enemy canonical spawns, tower demolition and ordinary incoming shots.

The scene suite additionally checks tower-button theme and generated audio data, keyboard role selection, pause/speed, terminal panels and high-camera invariants. Rendered QA exposed back-row towers overlapping the status strip: a failing scene-clearance assertion reproduced it; moving only the board's projected top from 120 to 140 resolved it, preserving topology and high camera pitch.

## Actual rendered QA

The initially unavailable display was resolved using a **parent-provisioned private authenticated Xvfb**. Frozen repo copies were exercised with real Godot GL Compatibility rendering, Mesa llvmpipe, 1280×720, and XTest mouse/keyboard input. This is actual game rendering, not a mocked image or headless screenshot.

Actual input played six waves to **CROSSING SECURED, 12/12 lives, 53 shattered, 0 escaped**, then restarted, played undefended to **THE GATE HAS FALLEN, 0/12 lives, 12 escaped**, then restarted again. A separate explicitly inflated-budget/health fixture exercised dense adjacent/chained barriers and selling; it is not presented as a balanced player strategy.

Evidence paths (outside Git):

- `/home/hermes/riftguard-evidence/complete-match-headless.log`
- `/home/hermes/riftguard-evidence/final/02-active-paused.png` — final projection, real input and active enemies.
- `/home/hermes/riftguard-evidence/final/03-wave-cleared.png` — final projection, first-wave clear.
- `/home/hermes/riftguard-evidence/final/04-restarted.png` — final projection, reset.
- `/home/hermes/riftguard-evidence/wave-6-result.png` — complete actual-input victory (before the presentation-only status clearance fix).
- `/home/hermes/riftguard-evidence/06-defeat.png` — actual-input defeat.
- `/home/hermes/riftguard-evidence/dense-final/03-breach-opened.png` — final dense-board clearance and chained demolition.
- `/home/hermes/riftguard-evidence/dense-final/04-sold-tower.png` — actual input selling in the dense fixture.
- `/home/hermes/riftguard-evidence/render-report.json`, `final/render-report.json`, `dense-final/render-report.json` — actions and cleanup.
- `/home/hermes/riftguard-evidence/render-game.log`, `final/render-game.log`, `dense-final/render-game.log` — renderer output.

Rendered logs contain **no runtime ERROR**. The only warning is the expected llvmpipe/Xvfb inability to change V-Sync mode. The bounded launchers deliberately terminate their own game processes after capture, stop/wait for Xvfb, and remove Xauthority; reports confirm display socket and lock removal. The Xvfb-only preload was never applied to Godot. No system packages/services were modified by this implementation.

## Remaining limitations / parent action

- **Audio listening is not verified**: generated PCM data and scene playback wiring pass; rendered sessions used Dummy audio. Native Windows feel/performance still needs review.
- Balance is deliberately approachable; a competent mixed defense wins without leaks. No campaign, difficulty selector, persistent save or multiplayer.
- `AGENTS.md` edits were denied by the protected-file tool guard. It remains unchanged. Parent must apply approved workflow/verification updates there; README and ROADMAP already distinguish internal small steps from integrated user milestones and record Multica project/milestone metadata.
- Parent owns independent review, Multica JOPE-47, commit and push. No implementation-agent commit, push or Multica mutation occurred.
