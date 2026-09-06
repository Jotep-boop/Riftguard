# Riftguard — Roadmap

## M1: Maze Prototype

- [x] Isometric logical grid
- [x] Routefinding from rift to gate
- [x] Place/remove blockers
- [x] Reject placements that seal the route
- [x] Moving enemy marker
- [x] Headless behavior tests
- [x] Windows playtest instructions

## M2: Combat Slice

Acceptance criteria for the first playable combat slice:

- Placed barricades act as towers and automatically target the enemy furthest along the route within range.
- Towers fire visible projectiles on a fixed cooldown; damage resolves only when a projectile lands.
- The enemy displays health, dies at zero health, grants gold exactly once, then respawns for continued testing.
- Hovering a tower shows its attack range, and shots, hits and kills have distinct readable feedback.
- Maze placement rules and the locked 13×9 long-side camera remain unchanged.

Tower breach acceptance criteria:

- Route-sealing towers are accepted instead of silently rejected.
- A blocked enemy follows a valid route to an open cell beside a reachable frontier tower.
- The enemy attacks that tower at a readable fixed cadence; tower health and impacts are visible.
- Destroyed towers are removed from board and combat state, navigation is recalculated, and the enemy resumes toward the gate or selects the next breach target.
- Towers do not shoot enemies while those enemies are actively attacking the same tower.

- [x] Tower targeting
- [x] Projectile and hit resolution
- [x] Enemy health and death
- [x] Kill reward economy
- [x] Tower health and enemy breach attacks when the route is sealed
- [x] Reachable breach-target selection and route recalculation after destruction
- [x] Range preview
- [x] Layered impact feedback

## M3: Complete Round

- [ ] Build and wave phases
- [ ] Gold, lives, victory and defeat
- [ ] Three tower roles
- [ ] Five tuned waves
- [ ] Restart and pause flow

## M4: Vertical Slice

- [ ] First cohesive faction
- [ ] Final-ish visual language
- [ ] Audio and settings
- [ ] Onboarding
- [ ] Performance and accessibility pass
