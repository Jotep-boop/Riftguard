# Strategic Replay verification

## Handoff

Verified live host/user `hermes` and clean `main` at `1d5b9d9` in `/home/hermes/projects/Riftguard`, then created **`feature/strategic-replay`**. Godot is `4.7.2.stable.official.ed1daf0bf`. The implementation remains **uncommitted and unpushed**, ready for the parent's independent review. Parent owns JOPE-48; no implementation-agent tracking calls or duplicate cards.

Board/pathfinder, `project.godot`, protected `AGENTS.md`, base Arc range 3 and camera constants are unchanged. No global installs, services, HA changes, licensed assets or secret output.

## Automated gate

`python3 tools/verify.py` passes all **seven** Godot checks plus `git diff --check`. The runner rejects `SCRIPT ERROR`, `ERROR:` and warnings even when Godot exits zero, and requires test completion markers.

- Import and main launch: exit 0.
- Original rules: `PASS: 24 tests`.
- Existing role/economy/lifecycle suite: `Match assertions failed: 0; assertions executed: 23`.
- Strategy suite: `Strategy failures: 0; assertions: 6801` (includes per-tick nonnegative-budget checks, not 6801 distinct test cases).
- Integration: `Integration failures: 0; peak concurrent enemies: 10`.
- Scene: `PASS: match scene, camera, HUD, placement, active wave, restart`.
- No errors or warnings in the final headless log.

Coverage includes exclusive/invalid/unaffordable branches, repair/cap/refunds, actual impacts for all six branch choices, chain nearest-neighbor/finite-count/once-only rewards, splash bounds, slow duration/area, dead-primary fizzle, actual Warden slow resistance, gate damage and breach damage, ledger isolation/reset/terminal immutability and effective damage excluding overkill. Original stationary breacher priority before movement and after replanning, ordinary breach targetability, incoming projectiles, canonical spawn, adjacent/chained barriers and Arc boundary regressions remain in the required gate. Scene tests exercise U→E choice, reinforcement, preview composition, terminal economy controls and a natural six-wave ledger's layout bounds.

## Observed RED → GREEN cycles

The focused command was Godot `--headless --path . --script res://tests/strategy_tests.gd`; scene changes used `res://tests/smoke_test.gd` with a bounded timeout because an assertion aborts the coroutine rather than quitting the tree.

| Slice | Observed RED | GREEN immediately after implementation |
|---|---|---|
| Exclusive branch purchase | exit 1, `explicit mutually exclusive upgrade branches exist`, 1 failure | 0 failures / 8 assertions |
| Actual branch impacts | exit 1, 7 failures: Lance latency, Chain neighbor/damage, Wide coverage/damage, Deep duration, Coldfront area | 0 failures / 17 assertions |
| Tactical waves/Warden | exit 1, `authored tactical wave preview exists` | 0 failures / 30 assertions |
| Measured results | exit 1, `measured match results exist` | 0 failures / 38 assertions |
| Branch-selection scene | assertion `branch chooser is available in the actual scene` | scene PASS after integration and preview-clearance fix |
| Full result layout | actual rendered run found result bottom 409 crossing retry at 382; scene reproduced `complete six-wave results must clear retry button` | result bottom 357; scene and full rendered run PASS |
| Terminal preview | scene assertion `terminal preview refers to wave that ended, not an unplayed next wave` | scene PASS with current terminal wave and disabled economy controls |

The full existing gate was rerun after each model cycle. The new HUD initially extended below the top-row tower clearance; moving the preview upward, not moving the approved camera or board, resolved that scene assertion. Earlier failed rendered copies are retained separately, not used as final evidence.

## Real-budget complete match simulations

Both strategies start with 240 salvage, place Arc `(3,3)`, Nova `(5,5)`, Frost `(5,3)`, Arc `(7,3)`, and buy only affordable upgrades/additional defenses between waves. No injected gold, health, kills, timing or final-state shortcuts. Both finish with 12 lives, 51 kills, zero escapes, 279 salvage and 865 gross spending; peak concurrency is 10. The original integration fixture and full-results scene simulation also win.

| Wave | Lives | Salvage at clear | Cumulative kills | Escapes | Primary wave time (s) | Alternate wave time (s) |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 12 | 120 | 6 | 0 | 6.90 | 6.90 |
| 2 | 12 | 125 | 14 | 0 | 5.35 | 5.12 |
| 3 | 12 | 170 | 26 | 0 | 7.82 | 5.38 |
| 4 | 12 | 192 | 32 | 0 | 12.23 | 11.25 |
| 5 | 12 | 190 | 42 | 0 | 10.27 | 10.15 |
| 6 | 12 | 279 | 51 | 0 | 14.40 | 16.27 |

Primary branches finish in **56.97 combat seconds**, dealing Arc 5197.75 / Nova 2780.95 / Frost 774.90 effective damage. Alternative branches finish in **55.07 seconds**, dealing Arc 4562.05 / Nova 2396.55 / Frost 1795.00. The compact scout wave is faster with coverage, while the Warden finale takes longer: measurable tradeoffs without making one branch mandatory.

Undefended simulation loses on wave 2: **0 kills, 12 escaped, 0 lives, 270 salvage, 21.55 combat seconds**, with the last wave marked incomplete. Win/loss restart tests clear economy, enemies/projectiles, board, ledger, counters and timers; additional terminal advances cannot add rewards or alter results.

## Actual rendered/input QA

Frozen copies run the real scene with Godot GL Compatibility / Mesa llvmpipe at 1280×720 in private authenticated Xvfb. Only Xvfb receives the relocation preload. The snapshot-only observer **reads** model/HUD state; XTest mouse/keyboard events do all natural-match purchasing, branch selection, launching and retrying. Readiness and wave completion use observed state predicates, not assumed sleeps. Source SHA256 comparison confirms final gameplay, main scene script, board, settings and tests match the verified snapshot.

The final natural-input session verified **all six choices**, keyboard and mouse selection, level-3 reinforcement, selling, pause, all six waves, the visible crowned Warden, victory results, the **clicked retry button**, 2× undefended defeat and R restart. Actual render results match the alternate deterministic simulation exactly: **51 kills, 12 lives, 0 escapes, 279 salvage, 55.07 combat seconds**. Result text is fully above the retry button. Fresh captures were visually inspected.

A separate explicitly labelled **4000-salvage stress fixture**, not a player-budget claim, rendered 18 branched towers in two complete adjacent/chained barriers. Actual input sold/rebuilt a back-row tower, launched the final wave, paused at the Warden, completed the breach fight and restarted. It recorded **9 kills, 0 escapes, 2 towers breached**, with readable dense branch labels and preview clearance.

### Evidence outside Git

- `/home/hermes/riftguard-evidence/strategic-replay-headless.log`
- `/home/hermes/riftguard-evidence/strategic-replay-simulations.json`
- `/home/hermes/riftguard-evidence/strategic-replay-artifact-check.log`
- `/home/hermes/riftguard-evidence/strategic-replay-verified/snapshot-sha256.json`
- `/home/hermes/riftguard-evidence/strategic-replay-verified/render-report.json`
- `/home/hermes/riftguard-evidence/strategic-replay-verified/render-game.log`
- `/home/hermes/riftguard-evidence/strategic-replay-verified/choice-chain.png` (also `choice-lance`, `choice-blast`, `choice-wide`, `choice-deep`, `choice-field`)
- `/home/hermes/riftguard-evidence/strategic-replay-verified/03-final-preview.png`
- `/home/hermes/riftguard-evidence/strategic-replay-verified/05-warden.png`
- `/home/hermes/riftguard-evidence/strategic-replay-verified/wave-6-result.png`
- `/home/hermes/riftguard-evidence/strategic-replay-verified/06-retry-button.png`
- `/home/hermes/riftguard-evidence/strategic-replay-verified/07-defeat-results.png`
- `/home/hermes/riftguard-evidence/strategic-replay-verified/08-loss-restart.png`
- `/home/hermes/riftguard-evidence/strategic-replay-dense/02-dense-warden-breach.png`
- `/home/hermes/riftguard-evidence/strategic-replay-dense/render-report.json`

Final natural/stress rendered scripts exit 0. Logs contain **no SCRIPT ERROR or ERROR**. The sole explicitly allowlisted warning is Xvfb/llvmpipe's known inability to change V-Sync mode; the first strict rendered log gate rejected it, then the exact warning—not general warnings—was classified as an expected driver limitation. Headless remains warning-free. Both launchers stop/wait for their own Godot and Xvfb, delete Xauthority, and verify socket/lock removal. Final `/proc` inspection found no remaining Godot/Xvfb processes.

## Limits / parent action

- Audio **listening is unverified**: generated PCM/playback wiring remains tested, rendered sessions use Dummy audio.
- Linux software-rendered QA is not native Windows feel/performance approval.
- Balance is deliberately approachable, not an exhaustive balance study. These competent strategies win without leaks; no difficulty selector, campaign or persistent progression was added.
- Parent independent review and shipping remain outstanding. No commit or push was made.
