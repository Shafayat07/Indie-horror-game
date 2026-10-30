# Development checklist — THE TIDE REMEMBERS

Legend: [x] done and verified · [~] done, partly verified · [ ] not done

## Environment / tooling
- [x] Godot 4.3 stable (official GitHub release) — `/opt/godot`, symlinked to `godot`
- [x] Python 3 + numpy + Pillow (preinstalled) for texture/audio generation
- [ ] Blender — not installed (download server blocked by the environment's network policy); key models are built procedurally in-engine instead
- [ ] Poly Haven / ambientCG / Kenney — blocked by network policy (HTTP 403); all textures and sounds generated procedurally instead

## Core systems
- [x] First-person controller: walk, sprint, crouch (headroom check), jump, gravity, collision
- [x] Flashlight (shadowed spot, slight lag), click is audible to The Listener
- [x] Interaction ray + prompts (generic Interactable, Door, notes)
- [x] Surface-aware footsteps (wood / stone / gravel / grass / metal / water) that emit noise
- [x] Field recorder: Listen (filters ambience, opens ListenOnly bus), Record (2.4 s, must stay in range), Replay (speaker noise + echo at the recording's origin)
- [x] PRE-ECHO system (signature swell, PreEcho reverb bus, tinted captions, Listener hears it)
- [x] The Listener: procedural rope/net model, procedural animation, independent head, DORMANT/ROAMING/INVESTIGATING/SEARCHING/HUNTING/RETURNING, navmesh pathing, stuck recovery, hunt timeout, safe-room repulsion, never passes doorways
- [x] Debug AI overlay (`--debug-ai` command-line flag only)
- [x] Death sequence + checkpoint reload
- [x] Save/continue (user://save.json), settings (user://settings.cfg)
- [x] Zone-based ambience mixer with nested interiors, reverb per space
- [x] Sea boundary (tide decides what is reachable)

## Content
- [x] A — Flooded Dock: boat radio pre-echo, footsteps that follow and take three more steps, shed + recorder tutorial
- [x] B — Settlement: teahouse radio → conversation from the blue house, backwards clock with key, wet footprints, lit windows, motionless bell pre-echo, Listener patrol, lighthouse wall + gate
- [x] C — Weather Station: fence + gate, fuel valve + generator, powered lights, hidden calibration tape, relay sequence (wrong order = blackout + reset), transmission lowers the tide
- [x] D — Tidal Caves: carved cave mesh, pools (loud water), mineral light, survey cable guide, drowned bell + acoustic seal, gallery Listener encounter, loose-plate lure
- [x] E — Lighthouse: walkable tower, contradicting tapes, seal release (hatch heard before pulled), beacon that stops when watched
- [x] Transmitter chamber: three couplings with pre-echo lure, valve lure, armed console, two choices
- [x] Ending A (break): overload, silence, Listener collapses, tide returns, quiet radio pre-echo on the boat
- [x] Ending B (send): transmission, Listener leaves, voices on every radio, radio speaks your next words on the boat
- [x] Main menu (live lighthouse scene), options, credits, pause menu, ending/credits screen

## Verification
- [x] Headless parse/import of all scripts, no errors
- [x] Level builds at every checkpoint
- [x] Rendered screenshots of all areas (software GL under Xvfb)
- [x] Automated full playthrough, both endings (tests/scenarios.gd)
- [x] Walk tests with real movement input on every critical route
- [x] AI state transitions, death/respawn tests
- [x] Windows export built (release/TheTideRemembers-windows.zip) — not executed (no Windows in the build environment)
- [x] Linux export built and smoke-tested headless
- [ ] Real-hardware performance (60 FPS) and audio mix by ear — needs a human playtest

## Possible next steps
- Human playtest for pacing, difficulty of the chamber, audio levels
- Replace the synthetic radio voice with recorded voice acting
- Sculpted Blender model for The Listener

## Final development phase
- [x] Backup tag `backup-before-final` before changes
- [x] Textures regenerated at 1024 px (+ masonry, whitewash, bark, slate, pine, skin, membrane, moss, cobble, painted wood)
- [x] Footsteps rebuilt (heel/toe, 6 variants per surface); rain, thunder, sonar, screech, stings, wingbeats
- [x] Blender models: lighthouse exterior, trees, Kell creature (tools/blender/build_models.py)
- [x] Story clarity: opening briefing, 10 chapter cards, journal [J], Elias's spoken thoughts, examine points
- [x] Horror: the Lodger (idle whisper), apparitions, house-entry scares (teahouse chair, office slam, blue-house window, station window), Listener glimpses, thirteen-second silence, jumpscare stings
- [x] Optional chapters: Blackwood + Old Radio Tower + Roost (Kell boss, hourly bell, sonar rule, floodlight), Ship Graveyard (Pelagic hold, radio incident), Low Vey (silence), Research Annex (Morrow, chase)
- [x] Body-horror scenes: annex exam room & containment, Pelagic cargo hold, Blackwood remains, Low Vey supper, Kell's nest
- [x] Third ending: The Last Recording (three optional recordings, no new puzzle)
- [x] Island clock, watch [T], rain and lightning
- [x] Existing puzzles untouched; both original full playthroughs still pass
- [x] Commits authored only by Shafayat07 (GitHub noreply address)
- [x] Fourth ending: The Light (Suha) — radio calls at the boat, the station and the armed chamber; lantern-room betrayal
- [x] Suha's soft voice (4 lines), her whispers and warm figure through the game, radio calls in her voice
- [x] Immersion pass: ground fog, dust, foghorn, cave drips, clutter in every location
- [x] Final suite: 17/17 scenarios pass
