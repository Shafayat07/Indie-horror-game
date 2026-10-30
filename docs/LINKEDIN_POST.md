After 3 months of work, I'm excited to share my indie horror game: THE TIDE REMEMBERS 🌊🕯️

It's a first-person supernatural horror game set on Vey Isle, a remote North Atlantic island that was removed from the charts in 1972. The old fishermen said the sea remembers everyone it takes, and sometimes it gives their voices back.

You play as Elias Vale, a technician sent to repair a dead weather station that has been calling for help for six years with no power. Then you notice your own footsteps arriving before you take them, and a radio playing your voice. Your name is already written in the records of the missing.

🎮 What makes it different
• Sound is the main mechanic. Some sounds on the island arrive before the things that make them.
• A field recorder lets you listen for hidden sounds, record them and replay them to lure danger away.
• The Listener is a creature made of wet rope and fishing nets. It can't see well, but it hears everything, even sounds that haven't happened yet.
• A boss who only leaves his cave when the village bell strikes the hour, and hunts by echolocation.
• 10 locations: a flooded dock, an abandoned village, a weather station, Blackwood forest, a ship graveyard, a drowned village revealed by low tide, tidal caves, an underground medical annex, a lighthouse and the transmitter chamber beneath it.
• Nine puzzles, an in-game journal, checkpoints, and four endings, including a secret one.
• No combat. You survive by listening, hiding and staying quiet.

🛠️ How it was built
• Engine: Godot 4.3 with GDScript.
• The whole island is put together in code at load time: terrain, buildings, interiors, caves and the lighthouse.
• All textures are generated in Python (NumPy) as full PBR sets, with a custom weathering shader for moss, grime and wet surfaces.
• 3D models are built with Blender Python scripts and exported as GLB.
• Sound effects are generated procedurally, using spatial audio and a separate audio layer for the "pre-echo" sounds.
• Voice lines come from an open-source text-to-speech model, with radio, tape and whisper effects.
• Automated test scenarios play the game from start to finish for every ending, walk every main route, and check the creature AI, save/load and the scares.
• Every tool used is free and open source.

The hardest part was the horror itself: deciding when to stay quiet, when to show something, and how to make a sound arriving three seconds early feel more frightening than a monster.

📸 Screenshots below.

I'd love to hear your feedback, and if you enjoy horror games, I'd be happy to share a build.

#GameDev #IndieGame #IndieDev #HorrorGame #Godot #GodotEngine #GameDesign #SoundDesign #ProceduralGeneration #Blender #Python
