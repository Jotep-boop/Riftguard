# Riftguard — Visual Direction

## Camera and projection

- Experimental fixed three-quarter view from one long side of a 13×9-cell board.
- The rift and gate remain centered on opposite 9-cell short sides.
- Enemies advance laterally across the screen from rift to gate.
- Grid rows widen mildly toward the camera to create perspective in pure 2D.
- The camera pitch stays high enough that near-side walls do not hide build cells behind them.
- Wall silhouettes remain lower than a projected cell's depth and grid outlines retain strong contrast.
- Towers grow upward from a clearly readable base footprint.
- Units remain readable against terrain at the target zoom.

## Initial palette

- Background: deep blue-black void.
- Safe build surface: desaturated slate and cold teal.
- Rift/source: magenta-violet.
- Guarded exit: warm gold.
- Valid placement: mint green.
- Invalid placement: coral red.
- Route debugging: cyan.

## Shape language

- Player defenses: stable, geometric, upward-pointing forms.
- Rift enemies: asymmetric, curved and fractured forms.
- Interaction markers: high contrast and consistent outlines.

## Complete-match assets

Everything is drawn procedurally by `main/main.gd`; no imported copyrighted/game-reference assets. Arc uses a mint diagonal conductor, Nova an amber ring, Frost a blue diamond. Scouts are violet spheres, runners golden arrowheads, brutes coral irregular pentagons. Health bars, contact shadows, slow rings and radial hit/death fragments share the slate crossing palette. HUD buttons have custom slate fills, borders and compact readable labels.

Audio is original mono 16-bit PCM synthesized at startup (22050 Hz): short decaying sine sweeps for shots, deaths, construction, waves, leaks and terminal outcomes. Eight low-volume voices cap overlap; M mutes. No files, libraries or network calls are required. These are functional placeholder cues, not final music or sound design. Their data and scene wiring are tested; no listening approval is claimed: the private rendered QA session used the Dummy audio driver.

## Polish rules

- Never rely on color alone; use shape and motion too.
- Every placed object needs a contact shadow.
- Effects may exaggerate impact but must not hide route readability.
- Placeholder art should already obey final proportions and silhouettes.
