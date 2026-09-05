# Riftguard Agent Rules

## Product invariants

- Keep `main` playable after every shipped change.
- Preserve the approved 13×9 logical board, start `(0, 4)`, goal `(12, 4)`, high long-side camera and left-to-right enemy flow unless Jeppe explicitly requests a redesign.
- Keep gameplay state and rules outside rendering code when practical; presentation consumes model state and events.
- Do not multiply content until the current vertical slice is stable, readable and fun.
- Route-sealing placement remains rejected until tower health, reachable breach targeting, enemy attacks, destruction feedback and route recalculation work together.

## Development workflow

- Develop behavior changes test-first: add one failing behavior test, verify the expected failure, implement the minimum rule, then run the focused and full suites.
- Keep changes small, reviewable and playable.
- Use an independent reviewer for substantial code changes before commit.
- Use feature branches or Git worktrees for parallel writers; never let two agents edit the same checkout concurrently.
- Do not commit secrets, generated import state or unlicensed assets.

## Required verification

Before committing code changes, run:

1. Godot editor import.
2. `res://tests/run_tests.gd`.
3. `res://tests/smoke_test.gd`.
4. A short headless launch of the main project.
5. `git diff --check`.

Treat `SCRIPT ERROR` and unexpected `ERROR:` output as failure even when Godot exits with status 0.

Use Godot 4.7.x. The verified Linux executable on the homelab is:

`/home/hermes/.local/opt/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`

Visual feel, composition, animation, audio and legibility still require a Windows playtest; headless checks are not visual approval.
