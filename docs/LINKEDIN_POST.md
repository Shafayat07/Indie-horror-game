# LinkedIn — main post (fits the 3,000-character limit)

3 months. One island. A sea that remembers.

I just finished my indie horror game, THE TIDE REMEMBERS 🌊🕯️

THE STORY
Vey Isle sits in the North Atlantic and was removed from the charts in 1972. The old fishermen had one rule: never answer a voice coming from the sea after the bell rings. They believed the sea remembers everyone it drowns and sometimes gives their voices back.

You are Elias Vale, a technician sent at night to fix a dead weather station that has been sending a distress call for six years with no power. You arrive at 23:40 to an empty harbour. Your footsteps keep walking after you stop. The radio plays your own voice. A drowned voice calls your name from under the dock. In the records of the missing, your name is already written, with a time of death: 03:12.

Along the way you uncover a village that drowned in 1923, a research project that tried to listen to the sea, doctors who operated on people's ears to make them hear it, and a radio operator who turned into something that hunts by sound.

THE GAMEPLAY
🎧 Sound is the main mechanic. Some sounds arrive before the things that make them.
📼 A field recorder lets you listen for hidden sounds, record them, and replay them to lure danger away.
🪢 The Listener is a creature made of wet rope and fishing nets. It sees poorly but hears everything.
🦇 A boss only leaves his cave when the bell strikes the hour, and hunts by echolocation.
🗺️ 10 locations, 9 puzzles, 4 endings (one secret), and no combat.

HOW I BUILT IT
⚙️ Godot 4.3 + GDScript. The whole island (terrain, houses, interiors, caves, a walkable lighthouse) is built from code when the game loads.
🎨 Every texture is generated in Python/NumPy as a PBR set, plus a custom shader that adds moss, grime and wet patches so nothing repeats.
🧱 3D models come from Blender Python scripts, exported as GLB.
🔊 All sound effects are synthesised in Python, with spatial audio, sound zones per area and a separate audio layer for the "early" sounds.
🗣️ Voices come from an open-source TTS model, processed into radio, tape, whisper and underwater effects.
🧠 Enemy AI uses navigation meshes, a hearing model and a state machine (roam, investigate, search, hunt).
✅ Automated scenarios play every ending start to finish, walk every route, and test the AI, saves and scares.
💸 Every tool is free and open source.

WHAT I LEARNED
The scariest moments came from timing, not monsters: a bell that rings while hanging still, footsteps three seconds early, a photo that changes when you stare at it.

Full build breakdown in the comments 👇 Screenshots below.

#GameDev #IndieGame #IndieDev #HorrorGame #Godot #GameDesign #SoundDesign #ProceduralGeneration #Blender #Python

---

# LinkedIn — article: "Building THE TIDE REMEMBERS: a 3-month horror game breakdown"

## The idea
I wanted a horror game where sound is both the threat and the tool. The core idea came from one question: what if you heard something before it happened? On Vey Isle, some sounds arrive early ("pre-echoes"). Your footsteps reach the dock before you do. A radio plays your voice saying words you haven't said yet. That one idea drives the story, the puzzles and the enemy.

## The story, in five lines
People drowned. Their voices stayed in the sea. Something beneath the island learned to use them. A warning bell was meant to keep people away. Researchers in the 1960s disturbed it, and now the island is calling again.

The player pieces this together from documents, radio messages, tapes, a journal and the places themselves. Nothing is explained in one long scene. The characters each have one clear motivation: Aldo Wren, the lighthouse keeper who saw the 1923 disaster; Ruth Marrow, the researcher who grew afraid of her own work; Edwin Morrow, the doctor who harmed people to make them "hear better"; Ines Halloran and her daughter Nell; Tomas Kell, the radio operator who joined to find his missing brother and became the creature in the forest; and Elias, who discovers the island has already recorded his death.

## Month 1: the foundation
• Engine choice: Godot 4.3 (free, open source, lightweight).
• Player controller: walking, sprinting, crouching, flashlight, mouse look, and a noise radius for every footstep based on speed and surface.
• The field recorder: Listen (a hidden audio layer opens), Record (capture a sound), Replay (the island throws the sound back to where it was recorded, which lures enemies).
• The Listener AI: navigation meshes baked per region, hearing and sight cones, and states for roaming, investigating, searching, hunting and returning. It walks toward sounds before they happen, never passes a doorway, and won't enter a room with a white ring on the door.
• First playable slice: the dock, the village and the weather station.

## Month 2: the world
• Procedural construction: the island isn't hand-placed. Terrain, buildings, rooms with door and window openings, cave tunnels, an octagonal lighthouse with walkable stairs, and a ship hold are all generated by helper functions in code. This kept collisions, footstep surfaces and materials consistent everywhere.
• Textures: a Python/NumPy generator produces 1024px albedo, normal and roughness maps (wood, stone, rust, concrete, rope, moss and more) with baked ambient occlusion, cracks and water streaks.
• Models: Blender Python scripts build the lighthouse, chapel, trees and the creature, exported as GLB with named materials the game swaps for its own.
• More areas: Blackwood forest and the radio tower, the ship graveyard, the drowned village of Low Vey (it only appears when the tide goes out), the tidal caves, the underground medical annex, the lighthouse and the transmitter chamber.
• The boss: Tomas Kell roosts in a cave and comes out for ten in-game minutes when the bell strikes the hour. He hunts with sonar clicks. Stand still, get under a roof, or catch him with your flashlight.

## Month 3: sound, story and polish
• Audio: every sound effect is synthesised in Python (footsteps on six surfaces, bells, radios, the creature, ambience beds), then mixed through separate buses: ambience, effects, pre-echo, voice and a "listen-only" layer.
• Voices: lines are generated with an open-source TTS model, then processed in Python to sound like a radio, a tape, a whisper, or a voice from underwater.
• Story delivery: chapter title cards, a journal that explains things in plain words, documents written in each character's voice, and subtitles for every spoken line.
• Horror design: a scare system with one-time events and a quiet gap between them. A presence whispers behind you if you stand still too long. Figures appear only where you aren't looking. A mirror really reflects the room, using a second camera, and once it shows someone standing behind you. Photographs on the walls slowly change when you stare at them. A bell strikes thirteen times at 3 a.m.
• Visual pass: a custom surface shader adds world-space grime, moss on sky-facing stone and wet patches, so tiling never repeats. Each location has its own fog colour, density and light.
• Endings: four endings, including a secret one that unlocks only if you find three optional recordings.

## Testing
I built an automated test driver that plays the game the way a player would. It covers full playthroughs for every ending, walking every main route with real movement input, the AI states, death and checkpoint reload, menus and mouse look, the boss, the scares and the voices. Walking the routes caught real bugs, like a boat rail that blocked the gangplank and a cave entrance you could fall through.

## Tools (all free)
Godot 4.3 · GDScript · Python (NumPy, Pillow) · Blender (Python API) · open-source TTS · Git

## What I'd tell anyone starting a horror game
1. Pick one mechanic and let everything grow from it.
2. Silence is a tool. The scare lands because of the quiet before it.
3. Give players rules they can learn (white rings are safe, stand still when you hear clicking), then make them doubt those rules.
4. Test by actually walking the routes. Bugs hide in doorways.
