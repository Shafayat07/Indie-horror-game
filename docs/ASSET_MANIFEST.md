# Asset manifest — THE TIDE REMEMBERS

Every texture and sound in this project is **original and generated procedurally** by scripts in `tools/`.
No third-party textures, models, sounds or music are used. The only third-party assets are two fonts.

## Third-party assets

| File | Type | Source | License | Attribution | Modifications |
|---|---|---|---|---|---|
| assets/fonts/SpecialElite-Regular.ttf | Font | https://github.com/google/fonts/tree/main/apache/specialelite (Google Fonts) | Apache License 2.0 (assets/fonts/SpecialElite-LICENSE.txt) | Special Elite by Astigmatic | None |
| assets/fonts/IBMPlexMono-Regular.ttf | Font | https://github.com/google/fonts/tree/main/ofl/ibmplexmono (Google Fonts) | SIL Open Font License 1.1 (assets/fonts/IBMPlexMono-OFL.txt) | IBM Plex Mono, © 2017 IBM Corp. | None |
| assets/audio/voice/*.wav (spoken lines; Elias's thoughts are text-only) | Speech | Generated offline with the Kokoro-82M TTS model (https://github.com/hexgrad/kokoro, weights via https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0) and kokoro-onnx; script: tools/gen_voice.py | Kokoro-82M: Apache License 2.0; kokoro-onnx: MIT | Voices: af_heart + af_nicole blend (Suha), bm_george (Elias on radio/tape), bf_emma, bm_lewis, bm_daniel, am_michael, am_eric, am_onyx | Radio/tape/whisper/reverb processing in tools/gen_voice.py |
| Godot Engine 4.3 (runtime) | Engine | https://godotengine.org | MIT | Godot Engine contributors | None |

## Original procedural assets

Generated with Python 3 + numpy + Pillow. Re-create them at any time with:

```bash
python3 tools/gen_textures.py
python3 tools/gen_audio.py
```

License: these files were created for this project and may be used under the same terms as the project itself.

### Textures (`assets/textures/`, 1024×1024 tileable PBR sets: albedo with baked cavity, normal, roughness)

| Set | Generator |
|---|---|
| bark | tools/gen_textures.py |
| cliff | tools/gen_textures.py |
| cobble | tools/gen_textures.py |
| concrete | tools/gen_textures.py |
| grass_coastal | tools/gen_textures.py |
| gravel | tools/gen_textures.py |
| membrane | tools/gen_textures.py |
| metal_green | tools/gen_textures.py |
| metal_red | tools/gen_textures.py |
| metal_rust | tools/gen_textures.py |
| moss | tools/gen_textures.py |
| pine | tools/gen_textures.py |
| plaster_white | tools/gen_textures.py |
| rock_cave | tools/gen_textures.py |
| roof | tools/gen_textures.py |
| rope | tools/gen_textures.py |
| sand_wet | tools/gen_textures.py |
| skin | tools/gen_textures.py |
| slate | tools/gen_textures.py |
| stone_blocks | tools/gen_textures.py |
| stone_wet | tools/gen_textures.py |
| wallpaper | tools/gen_textures.py |
| whitewash | tools/gen_textures.py |
| wood_dark | tools/gen_textures.py |
| wood_painted | tools/gen_textures.py |
| wood_planks | tools/gen_textures.py |

### Audio (`assets/audio/`, 22.05 kHz mono WAV, imported as QOA)

| File | Description |
|---|---|
| amb_cave.wav | ambience loop |
| amb_drone.wav | ambience loop |
| amb_generator.wav | ambience loop |
| amb_interior.wav | ambience loop |
| amb_rain.wav | ambience loop |
| amb_sea.wav | ambience loop |
| amb_signal.wav | ambience loop |
| amb_static.wav | ambience loop |
| amb_tape.wav | ambience loop |
| amb_wind.wav | ambience loop |
| amb_woods.wav | ambience loop |
| bell.wav | sound effect |
| bell_drowned.wav | sound effect |
| calibration_tape.wav | sound effect |
| chapel_bell.wav | sound effect |
| coupling.wav | sound effect |
| crystal_hum.wav | sound effect |
| death_sting.wav | sound effect |
| door_creak_0.wav | sound effect |
| door_creak_1.wav | sound effect |
| door_locked.wav | sound effect |
| door_slam.wav | sound effect |
| echo_footsteps_dock.wav | pre-echo sequence |
| echo_footsteps_stone.wav | pre-echo sequence |
| echo_footsteps_voice.wav | pre-echo sequence |
| echo_running.wav | pre-echo sequence |
| flashlight.wav | sound effect |
| flashlight_echo.wav | sound effect |
| generator_start.wav | sound effect |
| glass_break.wav | sound effect |
| hatch_open.wav | sound effect |
| heartbeat.wav | sound effect |
| knock3.wav | sound effect |
| listener_cry.wav | The Listener |
| listener_step_0.wav | The Listener |
| listener_step_1.wav | The Listener |
| listener_step_2.wav | The Listener |
| listener_strings.wav | The Listener |
| metal_knock.wav | sound effect |
| overload.wav | sound effect |
| paper.wav | sound effect |
| pickup.wav | sound effect |
| power_down.wav | sound effect |
| radio_burst.wav | sound effect |
| radio_voice_a.wav | distorted, deliberately unintelligible formant 'voice' (subtitled) |
| radio_voice_b.wav | distorted, deliberately unintelligible formant 'voice' (subtitled) |
| radio_voice_c.wav | distorted, deliberately unintelligible formant 'voice' (subtitled) |
| radio_voice_d.wav | distorted, deliberately unintelligible formant 'voice' (subtitled) |
| radio_voice_elias.wav | distorted, deliberately unintelligible formant 'voice' (subtitled) |
| rec_button.wav | sound effect |
| relay_0.wav | relay calibration tone |
| relay_1.wav | relay calibration tone |
| relay_2.wav | relay calibration tone |
| relay_wrong.wav | relay calibration tone |
| screech.wav | sound effect |
| sonar_0.wav | Kell's echolocation clicks |
| sonar_1.wav | Kell's echolocation clicks |
| sonar_2.wav | Kell's echolocation clicks |
| splash.wav | sound effect |
| step_grass_0.wav | footstep (heel + toe) |
| step_grass_1.wav | footstep (heel + toe) |
| step_grass_2.wav | footstep (heel + toe) |
| step_grass_3.wav | footstep (heel + toe) |
| step_grass_4.wav | footstep (heel + toe) |
| step_grass_5.wav | footstep (heel + toe) |
| step_gravel_0.wav | footstep (heel + toe) |
| step_gravel_1.wav | footstep (heel + toe) |
| step_gravel_2.wav | footstep (heel + toe) |
| step_gravel_3.wav | footstep (heel + toe) |
| step_gravel_4.wav | footstep (heel + toe) |
| step_gravel_5.wav | footstep (heel + toe) |
| step_metal_0.wav | footstep (heel + toe) |
| step_metal_1.wav | footstep (heel + toe) |
| step_metal_2.wav | footstep (heel + toe) |
| step_metal_3.wav | footstep (heel + toe) |
| step_metal_4.wav | footstep (heel + toe) |
| step_metal_5.wav | footstep (heel + toe) |
| step_stone_0.wav | footstep (heel + toe) |
| step_stone_1.wav | footstep (heel + toe) |
| step_stone_2.wav | footstep (heel + toe) |
| step_stone_3.wav | footstep (heel + toe) |
| step_stone_4.wav | footstep (heel + toe) |
| step_stone_5.wav | footstep (heel + toe) |
| step_water_0.wav | footstep (heel + toe) |
| step_water_1.wav | footstep (heel + toe) |
| step_water_2.wav | footstep (heel + toe) |
| step_water_3.wav | footstep (heel + toe) |
| step_water_4.wav | footstep (heel + toe) |
| step_water_5.wav | footstep (heel + toe) |
| step_wood_0.wav | footstep (heel + toe) |
| step_wood_1.wav | footstep (heel + toe) |
| step_wood_2.wav | footstep (heel + toe) |
| step_wood_3.wav | footstep (heel + toe) |
| step_wood_4.wav | footstep (heel + toe) |
| step_wood_5.wav | footstep (heel + toe) |
| sting_0.wav | jumpscare sting |
| sting_1.wav | jumpscare sting |
| sting_2.wav | jumpscare sting |
| switch_clunk.wav | sound effect |
| tape_start.wav | sound effect |
| tape_stop.wav | sound effect |
| thunder_0.wav | thunder |
| thunder_1.wav | thunder |
| thunder_2.wav | thunder |
| transmit_surge.wav | sound effect |
| ui_click.wav | sound effect |
| whisper_0.wav | breathy formant whisper |
| whisper_1.wav | breathy formant whisper |
| whisper_2.wav | breathy formant whisper |
| wingbeat.wav | sound effect |

### Models

- `assets/models/lighthouse.glb`, `trees.glb`, `kell.glb`, `chapel.glb` — original models made with **Blender 5.2.3**
  (the official `bpy` package from PyPI) by `tools/blender/build_models.py`. Re-create with
  `pip install bpy==5.2.3 && python tools/blender/build_models.py`. (`chapel.glb` is built but unused.)
- Everything else (The Listener, ghosts, field recorder, transmitter, boat, buildings, ships, furniture,
  rocks, caves, bodies) is generated at runtime from code in `scripts/`.
| assets/textures/photos/*.png | Old photographs (normal + haunted pairs) | Original, generated by tools/gen_photos.py (Pillow/numpy) | Project's own | — | Animated by the shader in scripts/world/photo.gd |
| assets/textures/macro.png | World-space variation map for the surface shader | Original, tools/gen_textures.py (macro) | Project's own | — | — |
| assets/shaders/surface.gdshader | Weathering surface shader | Original | Project's own | — | — |
