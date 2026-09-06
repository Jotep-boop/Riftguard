# Riftguard — Roadmap

## Shipped: Complete Match (`main` at `1d5b9d9`)

Approved 13×9 board/camera, finite match, three base tower roles, scout/runner/brute enemies, economy, repair-on-upgrade, refunds, gate lives, restart, concurrent navigation, normal breach targetability and original procedural graphics/audio. User played through the final wave without complaints; preserve these foundations.

## Strategic Replay — implemented, independent review pending

- [x] Two mutually exclusive, mechanically distinct branches per tower; locked reinforcement
- [x] Branch-choice UI with tradeoffs, keyboard/mouse selection and tower branch marks
- [x] Six authored tactical wave identities with true composition/spacing previews
- [x] Crowned Rift Warden finale with escorts, slow resistance, stronger breach and four-life escape
- [x] Measured match results: role damage, economy, combat time, tower losses and per-wave ledger
- [x] Full reset/retry without persistent progression or fabricated scores
- [x] Test-first behavior slices and rendered-QA fixes; existing stationary targeting/breach/range regressions retained
- [x] Budget-feasible primary and alternative full-match wins, undefended loss and restart simulations
- [x] Real rendered/input QA of all six choices, full finale, results, retry button and loss/restart in a frozen authenticated Xvfb session
- [ ] Parent independent review, commit and push (implementation deliberately uncommitted)
- [ ] Native Windows feel/performance and audio listening (Linux rendered QA uses Dummy audio)

## Later, only after holistic playtest

Balance/difficulty tuning, accessibility and performance passes, richer original artwork/audio. No campaign, faction expansion, persistent progression or multiplayer added here.

Internal test-driven cycles are implementation details, not separate user playtest milestones. Parent owns **JOPE-48**, issue `01a077b9-9a3f-74b5-b980-ca9694288ea7`, Riftguard project `d763e36c-785c-4330-b3ce-292bb1cf6646`. No implementation-agent Multica changes, duplicate cards, commits or pushes.
