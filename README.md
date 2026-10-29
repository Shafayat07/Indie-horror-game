# THE TIDE REMEMBERS

*A first-person psychological horror game about an island that hears the future.*

You are Elias Vale, a maintenance technician sent to Vey Isle to restore a dead
weather station and transmit its final diagnostic report. On Vey Isle, some
sounds arrive **before** the things that make them — and something on the
island is listening.

- Engine: **Godot 4.3** (GDScript, Forward+ renderer)
- Length: roughly 20–30 minutes; two endings
- No combat. Sound is how you survive.

---

## Running the game

### Option A — play the Windows build
If `build/windows/TheTideRemembers.exe` is present (see *Building* below), run it.
It is a single self-contained executable.

### Option B — run the project in Godot
1. Download **Godot 4.3 (standard, not .NET)** from https://godotengine.org/download/archive/4.3-stable/ (free).
2. Start Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5** (Play). The first launch imports assets, which takes a minute.

From the command line:

```bash
godot --path . 
```

### Building
Export templates for 4.3 are needed (Godot: *Editor → Manage Export Templates → Download*). Then:

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/TheTideRemembers.exe
```

A Linux preset is also included (`--export-release "Linux" build/linux/TheTideRemembers.x86_64`).

---

## Controls

| Key | Action |
|---|---|
| W A S D | Move |
| Mouse | Look |
| Shift | Sprint (loud) |
| Ctrl / C | Crouch (quiet, harder to see) |
| Space | Jump |
| E | Interact / read / close a note |
| F | Flashlight |
| Q | Recorder: **Listen** |
| R | Recorder: open the panel |
| Left mouse | With the panel open: **Record** (top slot) or **Replay** the selected recording |
| Mouse wheel / Tab / 1–9 | Select a recording |
| Esc | Pause (options, restart from checkpoint, main menu) |

Mouse sensitivity, master volume, FOV, invert-Y, subtitles, reduced screen
effects and volumetric fog can be changed in **Options** (main menu or pause).

## How the island works (no spoilers beyond the first minutes)

- **Pre-echoes** — sounds that arrive before their cause. They have a recognisable
  signature (a faint reversed swell and a long dark tail) and appear as pale-blue captions.
- **Listen** — through the recorder, the ambience falls away and hidden sounds emerge.
- **Record** — capture a nearby sound. Some only exist while you listen.
- **Replay** — the recorder's speaker plays it quietly *where you stand*… and then the
  island returns the sound, loudly, **to the place it was recorded**.
- **The Listener** hears footsteps (sprinting is loud; crouching is near-silent; water
  and metal are loud), doors, machines, your recorder — and sounds that have not
  happened yet. It sees only at short range; your flashlight makes you easier to see.
  It never passes through a doorway, and it will not enter a room marked with a
  **white ring** on the door.
- If you are caught, you return to the last checkpoint. Progress is saved automatically.

---

## Project layout

```
project.godot            engine config (autoloads: Game, Sound)
scenes/                  main_menu, island (the whole game), ending
scripts/autoload/        game.gd (state, saves, settings, input), sound.gd (mixer, pre-echo, noise)
scripts/player/          player.gd (controller), recorder.gd (listen/record/replay)
scripts/enemy/           listener.gd (AI state machine), listener_model.gd (procedural body + animation)
scripts/world/           island.gd (level root), build.gd (geometry helpers), props.gd,
                         terrain.gd, ocean.gd, door.gd, interactable.gd, zone.gd, recordable.gd
scripts/world/areas/     dock, settlement, station, caves, lighthouse, chamber
scripts/ui/              hud, menus, options, ending, theme
scripts/data/story.gd    every document, radio transmission, objective and recording
assets/                  generated textures + audio, fonts
tools/                   gen_textures.py, gen_audio.py (procedural asset generators)
tests/                   driver + scripted playthroughs (see below)
docs/                    DEV_CHECKLIST.md, ASSET_MANIFEST.md
```

The island is assembled from code at load time (≈3 s), so every location,
collider, navmesh and light can be read and changed in the area scripts.

## Debugging
`godot --path . -- --debug-ai` shows The Listener's current state and suspicion
above its head and prints timing/navigation info. Never enabled in a normal run.

## Testing

Automated scenarios drive the real game systems (zones, interactables, the
recorder, AI) with teleports standing in for walking:

```bash
tests/run_all.sh        # ai, death/respawn, full playthrough to each ending
tests/shoot.sh --cp=settlement "--shots=0,5.8,66,0,0"   # rendered screenshot (needs xvfb)
```

See **Testing status** below for what has and has not been verified.

## Credits and licenses
See `docs/ASSET_MANIFEST.md`. All textures, sounds and models are original and
procedurally generated for this project; fonts are Special Elite (Apache 2.0) and
IBM Plex Mono (OFL 1.1).
