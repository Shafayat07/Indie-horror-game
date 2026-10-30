# THE TIDE REMEMBERS

*A first-person psychological horror game about an island that hears the future.*

You are Elias Vale, a maintenance technician sent to Vey Isle to restore a dead
weather station and transmit its final diagnostic report. On Vey Isle, some
sounds arrive **before** the things that make them — and something on the
island is listening.

- Engine: **Godot 4.3** (GDScript, Forward+ renderer)
- Length: roughly 60–90 minutes with the optional chapters; four endings
- No combat. Sound is how you survive.

---

## Running the game

### Option A — play the Windows build
Unzip `release/TheTideRemembers-windows.zip` and run `TheTideRemembers.exe`.
It is a single self-contained executable (64-bit Windows, Vulkan-capable GPU).

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
| J | Elias's journal: what he has worked out so far, in plain words |
| T | Check your watch (the bell strikes the hour; Kell hunts for ten minutes after it) |
| Esc | Pause (options, restart from checkpoint, main menu) |
| F11 / Alt+Enter | Toggle fullscreen (also in Options) |

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

## Locations and chapters

| # | Location | Main path? | What happens there |
|---|---|---|---|
| I | Flooded Dock | yes | arrival, footstep pre-echo, recorder tutorial |
| II | Abandoned Settlement | yes | teahouse radio, backwards clock (station key), first Listener patrol, house scares |
| III | Weather Station | yes | fuel + generator, calibration tape, relay sequence B-A-C-A, transmission lowers the tide |
| IV | Blackwood Forest + Old Radio Tower | optional | Kell's hut and diaries, his roost, the bat-man boss and the floodlight |
| V | Ship Graveyard | optional | MV Pelagic's cargo hold, the radio incident, the mayday recording |
| VI | Low Vey (submerged village) | optional, low tide | the drowned village; the thirteen-second silence |
| VII | Tidal Caves | yes | drowned bell + acoustic seal, gallery stalked by the Listener |
| VIII | Research Annex (Project Morrow) | optional | examination room, containment, Morrow's tape, Listener chase |
| IX | Lighthouse | yes | contradicting tapes, the seal release heard before it is pulled |
| X | Transmitter chamber | yes | three couplings, the final choice |

**Endings**
- **Break the Signal** — overload the transmitter.
- **Send the Warning** — transmit the report.
- **The Light (Suha)** — Suha, Elias's love, calls him on the radio through the night in a soft, loving voice, and whispers to him between the scares ("wake up, love, it's only a dream"); now and then a warm figure in a pale dress stands far off and smiles. After the transmitter is armed she begs him to come up to the lantern room: "it's only a dream". Follow her voice (the ladder in the control room) and learn what the island did with it.
- **The Last Recording** (secret) — collect the three optional recordings (Morrow's tape in the Annex, the Pelagic mayday at the Ship Graveyard, Kell's tape from his roost) and a third option appears at the transmitter console. No extra puzzle is needed.

See `docs/STORY.md` for the story bible, and `docs/THE_TIDE_REMEMBERS_COMPLETE_GUIDE.md` (also as `.pdf`)
for the complete story, characters, locations, mechanics, puzzle solutions and endings in one document.

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

## Voices
Every spoken line is real synthesized speech (Kokoro TTS, Apache 2.0), generated offline by `tools/gen_voice.py`:
Elias (a calm British voice), Suha (soft and warm), and the radio and tape voices, each with its own radio,
tape or whisper treatment. Speech is always subtitled; captions for sound effects are optional
(Options → "Captions for sound effects", off by default).

## Credits and licenses
See `docs/ASSET_MANIFEST.md`. All textures, sounds and models are original and
procedurally generated for this project; fonts are Special Elite (Apache 2.0) and
IBM Plex Mono (OFL 1.1).

---

## Testing status

Everything below was run in a Linux cloud container **without a GPU, a sound
card or a human player**. Rendering used Mesa's software OpenGL (Godot's
Compatibility renderer) under Xvfb; the game itself targets Forward+.

| Check | How | Result |
|---|---|---|
| Project imports, all scripts parse | `godot --headless --import` | ✅ no errors |
| Level builds at every checkpoint | test driver, each checkpoint | ✅ (~2.7 s headless) |
| Full playthrough → **Ending A (break)** | `full_break` scenario: every objective, puzzle, recording, replay lure, relay sequence incl. a wrong attempt + reset, tide, caves, seal, lighthouse, couplings, choice, return trip, boat, ending screen | ✅ |
| Full playthrough → **Ending B (send)** | `full_send` scenario | ✅ |
| Walking every critical route with real movement input (boat → dock → settlement → station; station → cliff path → shelf → cave mouth; caves entrance → bell → seal → gallery → stair; all four lighthouse stair flights; lighthouse → gate → dock → boat) | `walk_*` scenarios | ✅ (these found and fixed 4 real blockers) |
| Listener AI: roam → hears loud noise → investigate; ignores a quiet far step; sees player → hunt; safe room → search; search timeout → return | `ai` scenario | ✅ |
| Caught → death sequence → reload at checkpoint | `death` scenario | ✅ |
| Replay echo lures The Listener toward the recording's origin | inside `full_*` | ✅ |
| Pause menu: pause/resume, mouse release, options open/close, settings saved to disk | `menus` scenario | ✅ |
| Main menu, HUD, notes, subtitles, all five areas render | screenshots (`tests/shoot.sh`) | ✅ visually checked |
| Windows export | `--export-release "Windows Desktop"` | ✅ builds (`release/TheTideRemembers-windows.zip`) — **not executed** (no Windows here) |
| Linux export of the same project | built and run headless with `--autostart` | ✅ loads all areas, no errors |

**Not verified:** frame rate on real hardware (60 FPS target unmeasured), the
Forward+ look (volumetric fog, shadows) on a GPU, audio mix levels by ear, menu
clicks with a real mouse, and real-player pacing (estimated 20–30 minutes).

## Testing status — final build

Automated scenarios (`tests/run_all.sh`), all run on the final code:

| Scenario | Covers | Result |
|---|---|---|
| full_break / full_send | every main-path objective and puzzle → endings A and B | ✅ |
| optional | ship radio + mayday, Kell's roost, tape, chase and floodlight death, Low Vey silence, Annex tape + Listener chase, **The Last Recording** ending | ✅ |
| kell_hunt | Kell emerges on the hour; standing still survives his sonar; moving in the open gets you caught | ✅ |
| suha | Suha's final call, the lantern-room climb, ending THE LIGHT | ✅ |
| horror | the Lodger whisper, apparition appears/vanishes, journal, watch | ✅ |
| ai, death, menus, mouselook | Listener states, catch → checkpoint reload, pause/options, mouse look | ✅ |
| voices | every spoken line has a voice file and it plays on the Voice bus | ✅ |
| walk_* (7 routes) | real movement input over every main and forest route | ✅ |

## Known limitations

- Models are procedural (built in code or by a Blender script), so the look is
  stylised low-poly rather than sculpted.
- Free asset libraries (Poly Haven, ambientCG, Kenney) were blocked by the build
  environment's network policy, so every texture and sound is procedurally generated.
- Voices are synthesized, not acted; they are clear but not as expressive as a voice actor.
- The Windows `.exe` is unsigned; Windows SmartScreen may warn on first launch
  (*More info → Run anyway*).
- If a GPU lacks Vulkan, run with `--rendering-driver opengl3`; volumetric fog is
  then unavailable (Compatibility renderer).

## Tools used (all free)

| Tool | Version | Source | Purpose |
|---|---|---|---|
| Godot Engine | 4.3-stable | github.com/godotengine/godot releases (official) | engine, export |
| Godot export templates | 4.3-stable | same release page | Windows/Linux builds |
| Python 3 + numpy + Pillow | preinstalled | — | texture and audio generation |
| Xvfb + Mesa llvmpipe | preinstalled | — | headless rendering for screenshots |
