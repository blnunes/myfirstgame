# Dynamic Dog Adventures

A small top-down game prototype for Godot 4.7. Move the dog through Forest, City, Desert, and Space scenarios and find the highlighted object in each world.

## Gameplay

- Forest: pee on the highlighted tree.
- City: find the fire hydrant.
- Desert: find the cactus.
- Space: wear a helmet and find the meteor.

Touching the target plays a short effect, moves the target to a new random tile, and switches to a different random scenario. All graphics and audio are generated in code except for the dog PNG.

A game lasts for 10 targets. The final time can enter a persistent Top 10 leaderboard. Qualifying players register exactly three arcade-style initials using only the letters `A-Z`; numbers, accents, spaces, and symbols are rejected.

## Run

1. Open this directory with Godot 4.7.
2. Open `MainScene.tscn` if it is not already selected.
3. Run the project.

Use the arrow keys to move. See `AGENTS.md` for architecture, extension guidance, and the manual validation checklist.
