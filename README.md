# Aeolis: A Mars Science Expedition

A small story campaign built on the supplied Mars exploration GDScript. The player is a field geologist on the Aeolis mission, sent to check an orbiter's hint of ancient water in Gale Crater. Design the science payload, visit three outcrops, return to the lander, and uplink evidence to the science team on Earth.

## Open and play

1. Install Godot 4.3 or newer.
2. In Godot, choose **Import** and select `project.godot` in this folder.
3. Press **F6/F5** (or the Play button).
4. Use **W/A/S/D** to move, **Shift** to sprint, **Space** to jump, **E** for the jetpack, **F** to collect a nearby sample, **C** to uplink at the lander, and **J** to open the mission journal. **F1** toggles the telemetry panel; **F2** toggles the dust-storm drill.

The opening journal asks you to choose a compatible science objective and telescope design. For the story's ancient-water investigation, choose ancient water, infrared, imaging spectrometer, and reflecting telescope, then verify the design. Explore the three sample sites marked by the existing mission HUD. Finish by returning to the lander near your starting point and pressing **C**.

## Story and mission design

- The briefing frames the scientific need and a short Mission Design Lab trade study.
- The design steps echo CML 1–4: science need, feasibility trade, point design, and field verification.
- Mission segments connect launch and deployment, orbital mapping, ground operations, and Earth-based science analysis.
- The story advances as basalt, clay-bearing rock, and dune samples are collected. The final science packet unlocks the ending.
- Mission telemetry and the existing orbital relay schematic remain in the original HUD.

## Assets

The single game script includes the story journal as an inner class, procedural Mars terrain, and a procedural astronaut suit placeholder, so the game has a visible character without downloads. The original script can optionally load higher fidelity assets from `assets/codex_upgrade/` (Mars albedo/normal/roughness textures, map and height data, Bagnold dune textures, and `NASA_Astronaut.glb`). Those files were not included with the supplied script, so the game falls back to procedural terrain and the built-in suit. Add the optional files at those paths to use them. No NASA API, GMAT, or Mission Viz connection is used; all mission displays are in-game simulations.

## Files

- `MarsExplorationMission.gd` — complete game and story in one script.
- `Main.tscn` and `project.godot` — runnable Godot project entry point and settings.

## NASA Space Apps

A truthful project-page text draft is in [SPACE_APPS_SUBMISSION_DRAFT.md](SPACE_APPS_SUBMISSION_DRAFT.md). The game is NASA/CSA resource-informed; it does not currently ingest NASA datasets or connect to NASA services.

